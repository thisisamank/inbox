import 'package:api/api.dart';

typedef ChannelFactory =
    AgentChannel Function(AccessSession session, String mailboxId);

class AgentRepository {
  AgentRepository(this._client, {ChannelFactory? channels})
    : _channels =
          channels ??
          ((session, mailboxId) => SocketAgentChannel(session, mailboxId));

  final ApiClient _client;
  final ChannelFactory _channels;

  Future<List<Json>> history(String mailboxId) async => [
    for (final m in await _client.agent.messages(mailboxId))
      Map<String, dynamic>.from(m! as Map),
  ];

  Future<AgentChannel> open(String mailboxId) async =>
      _channels(await _client.requireSession(), mailboxId);
}
