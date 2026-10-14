import 'package:api/api.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/agent_chat.dart';
import 'agent_chat_notifier.dart';

part 'rewrite_notifier.g.dart';

String rewritePrompt(String text) =>
    'Rewrite the email text below so it is clear, friendly and concise. Keep the meaning and the language. '
    'Reply with only the rewritten text. Do not call any tools and do not add commentary.\n\n---\n$text';

@immutable
class RewriteState {
  const RewriteState({
    this.sent = false,
    this.result = '',
    this.done = false,
    this.error,
    this.connecting = true,
  });

  final bool sent;
  final String result;
  final bool done;
  final String? error;
  final bool connecting;
}

@riverpod
class Rewrite extends _$Rewrite {
  int? _sentAt;
  bool _sending = false;

  @override
  RewriteState build(String mailboxId, String text) {
    final chat = ref.watch(agentChatProvider(mailboxId));
    if (_sentAt == null && !_sending && chat.canSend) {
      _sending = true;
      Future.microtask(_send);
    }
    return _from(chat);
  }

  void _send() {
    _sending = false;
    if (!ref.mounted || _sentAt != null) return;
    final before = ref.read(agentChatProvider(mailboxId)).messages.length;
    if (ref
        .read(agentChatProvider(mailboxId).notifier)
        .send(rewritePrompt(text))) {
      _sentAt = before;
      ref.invalidateSelf();
    }
  }

  RewriteState _from(ChatState chat) {
    final sentAt = _sentAt;
    if (sentAt == null) {
      return RewriteState(
        connecting: chat.connection != AgentConnection.online,
        error: chat.error,
      );
    }
    final replies = chat.messages
        .skip(sentAt)
        .where((m) => m['role'] == 'assistant')
        .toList();
    final result = replies.isEmpty ? '' : messageText(replies.last);
    return RewriteState(
      sent: true,
      connecting: false,
      result: result,
      done: !chat.streaming && result.isNotEmpty,
      error: chat.error,
    );
  }
}
