import 'package:agentic_inbox/notifier/threads_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  late Fakes fakes;
  late ProviderContainer container;

  setUp(() async {
    fakes = await registerFakes();
    fakes.server
      ..on('GET', '$mailboxPathPrefix/emails', (r) {
        final page = r.queryParameters['page'];
        return page == '2'
            ? {
                'emails': [threadJson(id: 'c')],
                'totalCount': 3,
              }
            : {
                'emails': [
                  threadJson(id: 'a', threadId: 't1'),
                  threadJson(id: 'b'),
                ],
                'totalCount': 3,
              };
      })
      ..on('GET', '$mailboxPathPrefix/folders', (_) => <Object>[])
      ..on(
        'GET',
        '$mailboxPathPrefix/threads/t1',
        (_) => [
          emailJson(id: 'a', threadId: 't1'),
          emailJson(id: 'a2', threadId: 't1', folder: 'sent'),
          emailJson(id: 'a3', threadId: 't1'),
        ],
      )
      ..on(
        'POST',
        '$mailboxPathPrefix/emails/a/move',
        (_) => {'status': 'moved'},
      )
      ..on(
        'POST',
        '$mailboxPathPrefix/emails/a3/move',
        (_) => {'status': 'moved'},
      );
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await tearDownFakes();
  });

  test(
    'the first page loads and more pages append without duplicates',
    () async {
      final provider = threadsProvider(mailboxId, 'inbox');
      container.listen(provider, (_, _) {});
      final first = await container.read(provider.future);
      expect(first.threads.map((t) => t.id), ['a', 'b']);
      expect(first.hasMore, isTrue);
      await container.read(provider.notifier).loadMore();
      final next = container.read(provider).value!;
      expect(next.threads.map((t) => t.id), ['a', 'b', 'c']);
      expect(next.hasMore, isFalse);
    },
  );

  test(
    'archive removes the row at once, moves only inbox mail, and undo moves it back',
    () async {
      final provider = threadsProvider(mailboxId, 'inbox');
      container.listen(provider, (_, _) {});
      final list = await container.read(provider.future);
      final outcome = await container
          .read(provider.notifier)
          .move(list.threads.first, to: 'archive', label: 'Archive');
      expect(outcome.message, 'Moved to Archive');
      expect(fakes.server.calls.where((c) => c.startsWith('POST')), [
        'POST $mailboxPathPrefix/emails/a/move',
        'POST $mailboxPathPrefix/emails/a3/move',
      ]);
      expect(
        fakes.server.requests
            .where((r) => r.method == 'POST')
            .map((r) => r.data),
        [
          {'folderId': 'archive'},
          {'folderId': 'archive'},
        ],
      );
      fakes.server.requests.clear();
      await outcome.undo!();
      expect(
        fakes.server.requests
            .where((r) => r.method == 'POST')
            .map((r) => r.data),
        [
          {'folderId': 'inbox'},
          {'folderId': 'inbox'},
        ],
      );
    },
  );

  test('a failed move puts the row back and rethrows', () async {
    final provider = threadsProvider(mailboxId, 'inbox');
    container.listen(provider, (_, _) {});
    final list = await container.read(provider.future);
    fakes.server.routes.remove('POST $mailboxPathPrefix/emails/a/move');
    await expectLater(
      container
          .read(provider.notifier)
          .move(list.threads.first, to: 'archive', label: 'Archive'),
      throwsA(anything),
    );
    expect(container.read(provider).value!.threads.map((t) => t.id), [
      'a',
      'b',
    ]);
  });
}
