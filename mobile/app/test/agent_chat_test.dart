import 'dart:convert';

import 'package:agentic_inbox/models/agent_chat.dart';
import 'package:agentic_inbox/notifier/agent_chat_notifier.dart';
import 'package:api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  tearDown(tearDownFakes);

  test(
    'history loads, a message streams in, and the history reloads when it ends',
    () async {
      final fakes = await registerFakes();
      var history = <Object>[
        {
          'id': 'u1',
          'role': 'user',
          'parts': [
            {'type': 'text', 'text': 'hi'},
          ],
        },
      ];
      fakes.server.on(
        'GET',
        '/agents/email-agent/$mailboxId/get-messages',
        (_) => history,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = agentChatProvider(mailboxId);
      container.listen(provider, (_, _) {});

      await pumpEventQueue();
      fakes.channel.connect();
      await pumpEventQueue();
      expect(container.read(provider).connection, AgentConnection.online);
      expect(container.read(provider).historyLoaded, isTrue);

      expect(
        container.read(provider.notifier).send('how many emails?'),
        isTrue,
      );
      final frame = fakes.channel.sent.single;
      final id = frame['id'] as String;
      final sent =
          (jsonDecode((frame['init'] as Map)['body'] as String)
                  as Map)['messages']
              as List;
      expect(sent.map((m) => (m as Map)['id']).first, 'u1');
      expect(container.read(provider).streaming, isTrue);

      fakes.channel.emit({
        'type': 'cf_agent_use_chat_response',
        'id': id,
        'body': jsonEncode({'type': 'text-delta', 'delta': 'Two.'}),
        'done': false,
      });
      await pumpEventQueue();
      expect(messageText(container.read(provider).messages.last), 'Two.');

      history = [
        ...history,
        {
          'id': 'u2',
          'role': 'user',
          'parts': [
            {'type': 'text', 'text': 'how many emails?'},
          ],
        },
        {
          'id': 'a2',
          'role': 'assistant',
          'parts': [
            {'type': 'text', 'text': 'Two.'},
          ],
        },
      ];
      fakes.channel.emit({
        'type': 'cf_agent_use_chat_response',
        'id': id,
        'body': '',
        'done': true,
      });
      await pumpEventQueue();
      final state = container.read(provider);
      expect(state.streaming, isFalse);
      expect(state.messages.map((m) => m['id']), ['u1', 'u2', 'a2']);
    },
  );

  test('a clear from another device empties the conversation', () async {
    final fakes = await registerFakes();
    fakes.server.on(
      'GET',
      '/agents/email-agent/$mailboxId/get-messages',
      (_) => [
        {'id': 'u1', 'role': 'user', 'parts': <Object>[]},
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = agentChatProvider(mailboxId);
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    fakes.channel.emit({'type': 'cf_agent_chat_clear'});
    await pumpEventQueue();
    expect(container.read(provider).messages, isEmpty);
  });
}
