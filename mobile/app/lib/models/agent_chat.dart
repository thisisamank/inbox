import 'package:api/api.dart';
import 'package:flutter/foundation.dart';

enum AgentConnection { connecting, online, offline }

@immutable
class ChatState {
  const ChatState({
    this.messages = const [],
    this.connection = AgentConnection.connecting,
    this.historyLoaded = false,
    this.streaming = false,
    this.error,
  });

  final List<Json> messages;
  final AgentConnection connection;
  final bool historyLoaded;
  final bool streaming;
  final String? error;

  bool get canSend =>
      connection == AgentConnection.online && historyLoaded && !streaming;

  ChatState copyWith({
    List<Json>? messages,
    AgentConnection? connection,
    bool? historyLoaded,
    bool? streaming,
    String? Function()? error,
  }) => ChatState(
    messages: messages ?? this.messages,
    connection: connection ?? this.connection,
    historyLoaded: historyLoaded ?? this.historyLoaded,
    streaming: streaming ?? this.streaming,
    error: error == null ? this.error : error(),
  );
}
