import 'package:agentic_inbox/models/thread.dart';
import 'package:agentic_inbox/notifier/conversation_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  late Fakes fakes;
  late ProviderContainer container;
  const ref = ThreadRef(emailId: 'a', threadId: 't1');

  setUp(() async {
    fakes = await registerFakes();
    fakes.server
      ..on(
        'GET',
        '$mailboxPathPrefix/threads/t1',
        (_) => [
          emailJson(id: 'a', threadId: 't1'),
          emailJson(
            id: 'd',
            threadId: 't1',
            folder: 'draft',
            recipient: 'priya@vendor.com',
            inReplyTo: 'a',
            body: '<p>Friday works.</p>',
          ),
        ],
      )
      ..on(
        'POST',
        '$mailboxPathPrefix/threads/t1/read',
        (_) => {'status': 'marked_read'},
      )
      ..on(
        'GET',
        mailboxPathPrefix,
        (_) => {
          'id': mailboxId,
          'email': mailboxId,
          'settings': {'fromName': 'Aman'},
        },
      )
      ..on(
        'POST',
        '$mailboxPathPrefix/emails/a/reply',
        (_) => {'id': 'n', 'status': 'sent'},
      )
      ..on('DELETE', '$mailboxPathPrefix/emails/d', (_) => null);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await tearDownFakes();
  });

  test('opening a thread loads it and marks it read once', () async {
    final provider = conversationProvider(mailboxId, ref);
    container.listen(provider, (_, _) {});
    final messages = await container.read(provider.future);
    expect(messages.map((m) => m.id), ['a', 'd']);
    expect(messages.first.senderName, 'Priya Raman');
    await pumpEventQueue();
    expect(fakes.server.calls.where((c) => c.endsWith('/read')), [
      'POST $mailboxPathPrefix/threads/t1/read',
    ]);
  });

  test(
    'sending an agent draft replies to the original, then deletes the draft',
    () async {
      final provider = conversationProvider(mailboxId, ref);
      container.listen(provider, (_, _) {});
      final messages = await container.read(provider.future);
      fakes.server.calls.clear();
      await container.read(provider.notifier).sendDraft(messages.last);
      expect(
        fakes.server.calls,
        containsAllInOrder([
          'GET $mailboxPathPrefix',
          'POST $mailboxPathPrefix/emails/a/reply',
          'DELETE $mailboxPathPrefix/emails/d',
        ]),
      );
      final reply =
          fakes.server.requests
                  .firstWhere((r) => r.uri.path.endsWith('/reply'))
                  .data
              as Map;
      expect(reply['from'], {'email': mailboxId, 'name': 'Aman'});
      expect(reply['to'], 'priya@vendor.com');
      expect(reply['text'], 'Friday works.');
    },
  );
}
