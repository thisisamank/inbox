import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import 'access_session.dart';
import 'json.dart';

Uri agentUri(Uri baseUrl, String mailboxId) => Uri.parse(
  '${baseUrl.scheme == 'http' ? 'ws' : 'wss'}://${baseUrl.authority}/agents/email-agent/$mailboxId',
);

abstract interface class AgentChannel {
  Future<void> get ready;
  Stream<Json> get events;
  void send(Json message);
  void close();
}

class SocketAgentChannel implements AgentChannel {
  SocketAgentChannel(AccessSession session, String mailboxId)
    : _channel = IOWebSocketChannel.connect(
        agentUri(session.baseUrl, mailboxId),
        headers: session.headers,
        pingInterval: const Duration(seconds: 25),
      );

  final IOWebSocketChannel _channel;

  @override
  Future<void> get ready => _channel.ready;

  @override
  Stream<Json> get events => _channel.stream
      .where((raw) => raw is String)
      .map((raw) {
        try {
          return jsonDecode(raw as String);
        } on FormatException {
          return null;
        }
      })
      .where((m) => m is Map<String, dynamic>)
      .cast<Json>();

  @override
  void send(Json message) => _channel.sink.add(jsonEncode(message));

  @override
  void close() => _channel.sink.close();
}

({List<Json> history, Json frame}) buildChatRequest(
  List<Json> messages,
  String text, {
  required String userMessageId,
  required String requestId,
}) {
  final history = [
    ...messages.where((m) => !(m['id'] as String? ?? '').startsWith('stream-')),
    {
      'id': userMessageId,
      'role': 'user',
      'parts': [
        {'type': 'text', 'text': text},
      ],
    },
  ];
  return (
    history: history,
    frame: {
      'type': 'cf_agent_use_chat_request',
      'id': requestId,
      'init': {
        'method': 'POST',
        'body': jsonEncode({'messages': history, 'trigger': 'submit-message'}),
      },
    },
  );
}
