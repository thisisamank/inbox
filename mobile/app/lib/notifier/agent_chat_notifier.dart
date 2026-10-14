import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:api/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../models/agent_chat.dart';

part 'agent_chat_notifier.g.dart';

String randomId([int length = 16]) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

@riverpod
class AgentChat extends _$AgentChat {
  AgentChannel? _channel;
  StreamSubscription<Json>? _events;
  Timer? _retry;
  int _attempt = 0;
  String? _active;
  final _streams = <String, Json>{};

  @override
  ChatState build(String mailboxId) {
    ref.onDispose(_teardown);
    unawaited(_start());
    return const ChatState();
  }

  void _teardown() {
    _retry?.cancel();
    _events?.cancel();
    _channel?.close();
    _channel = null;
    _streams.clear();
    _active = null;
  }

  Future<void> _start() async {
    await refreshHistory();
    await _connect();
  }

  Future<void> refreshHistory() async {
    try {
      final history = await agent.history(mailboxId);
      if (!ref.mounted) return;
      final pending = _streams.values.where(
        (m) => !history.any((h) => h['id'] == m['id']),
      );
      state = state.copyWith(
        messages: [...history, ...pending],
        historyLoaded: true,
        error: () => null,
      );
    } on ApiFailure catch (failure) {
      if (ref.mounted) {
        state = state.copyWith(
          error: () => 'Could not load the conversation: ${failure.message}',
        );
      }
    }
  }

  Future<void> _connect() async {
    if (!ref.mounted) return;
    state = state.copyWith(connection: AgentConnection.connecting);
    final AgentChannel channel;
    try {
      channel = await agent.open(mailboxId);
    } on Object catch (_) {
      _scheduleReconnect();
      return;
    }
    if (!ref.mounted) {
      channel.close();
      return;
    }
    _channel = channel;
    _events = channel.events.listen(
      _onEvent,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );
    channel.ready.then((_) {
      if (_channel != channel || !ref.mounted) return;
      _attempt = 0;
      state = state.copyWith(connection: AgentConnection.online);
    }, onError: (_) => _scheduleReconnect());
  }

  void _scheduleReconnect() {
    if (!ref.mounted || _retry?.isActive == true) return;
    _events?.cancel();
    _channel = null;
    final dropped = _active != null;
    _active = null;
    _streams.clear();
    state = state.copyWith(
      connection: AgentConnection.offline,
      streaming: false,
      error: dropped
          ? () => 'The connection dropped while the agent was replying.'
          : null,
    );
    final delay = Duration(seconds: min(30, 1 << min(_attempt, 5)));
    _attempt++;
    _retry = Timer(delay, () => unawaited(_start()));
  }

  void reconnectNow() {
    _retry?.cancel();
    _attempt = 0;
    _events?.cancel();
    _channel?.close();
    _channel = null;
    unawaited(_start());
  }

  void _onEvent(Json data) {
    if (!ref.mounted) return;
    switch (data['type']) {
      case 'cf_agent_chat_messages':
        if (_active != null) return;
        state = state.copyWith(
          messages: [
            for (final m in data['messages'] as List? ?? const [])
              Map<String, dynamic>.from(m as Map),
          ],
        );
      case 'cf_agent_message_updated':
        final updated = Map<String, dynamic>.from(data['message'] as Map);
        final i = state.messages.indexWhere((m) => m['id'] == updated['id']);
        state = state.copyWith(
          messages: i >= 0
              ? ([...state.messages]..[i] = updated)
              : [...state.messages, updated],
        );
      case 'cf_agent_chat_clear':
        _streams.clear();
        state = state.copyWith(messages: const []);
      case 'cf_agent_use_chat_response':
        _onChunk(data);
    }
  }

  void _onChunk(Json data) {
    final id = data['id'] as String?;
    if (id == null) return;
    var message = _streams[id];
    var messages = state.messages;
    if (message == null) {
      message = {'id': 'stream-$id', 'role': 'assistant', 'parts': <Json>[]};
      _streams[id] = message;
      messages = [...messages, message];
    }
    final body = data['body'] as String?;
    String? error;
    if (data['error'] == true) {
      error = (body == null || body.trim().isEmpty)
          ? 'The agent hit an error.'
          : body;
    } else if (body != null && body.trim().isNotEmpty) {
      try {
        applyChunk(
          (message['parts'] as List).cast<Json>(),
          jsonDecode(body) as Json,
        );
      } on FormatException {
        (message['parts'] as List).add(<String, dynamic>{
          'type': 'text',
          'text': body,
          'state': 'done',
        });
      }
    }
    final finished = data['done'] == true || data['error'] == true;
    if (finished) {
      _streams.remove(id);
      if (_active == id) _active = null;
    }
    state = state.copyWith(
      messages: [...messages],
      streaming: _active != null || _streams.isNotEmpty,
      error: error == null ? null : () => error,
    );
    if (finished) unawaited(refreshHistory());
  }

  bool send(String text) {
    final channel = _channel;
    final trimmed = text.trim();
    if (trimmed.isEmpty ||
        channel == null ||
        !state.canSend ||
        _active != null) {
      return false;
    }
    final request = buildChatRequest(
      state.messages,
      trimmed,
      userMessageId: randomId(),
      requestId: randomId(8),
    );
    final requestId = request.frame['id'] as String;
    _active = requestId;
    final placeholder = <String, dynamic>{
      'id': 'stream-$requestId',
      'role': 'assistant',
      'parts': <Json>[],
    };
    _streams[requestId] = placeholder;
    state = state.copyWith(
      messages: [...request.history, placeholder],
      streaming: true,
      error: () => null,
    );
    channel.send(request.frame);
    return true;
  }

  void stop() {
    final id = _active;
    if (id != null) {
      _channel?.send({'type': 'cf_agent_chat_request_cancel', 'id': id});
    }
  }

  void clear() {
    _channel?.send({'type': 'cf_agent_chat_clear'});
    _streams.clear();
    _active = null;
    state = state.copyWith(messages: const [], streaming: false);
  }
}
