import 'package:agentic_inbox/models/session_state.dart';
import 'package:agentic_inbox/notifier/mailboxes_notifier.dart';
import 'package:agentic_inbox/notifier/session_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  tearDown(tearDownFakes);

  test(
    'without a stored session the app is signed out and remembers the last inbox',
    () async {
      await registerFakes(signedIn: false);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = await container.read(sessionProvider.future);
      expect(
        state,
        isA<SignedOut>().having((s) => s.lastInbox, 'lastInbox', inbox),
      );
    },
  );

  test('a stored session restores the inbox and the chosen mailbox', () async {
    await registerFakes();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = await container.read(sessionProvider.future);
    expect(
      state,
      isA<SignedIn>().having((s) => s.mailboxId, 'mailboxId', mailboxId),
    );
  });

  test('an Access redirect on any call expires the session', () async {
    final fakes = await registerFakes();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(sessionProvider.future);
    fakes.server
      ..status = 302
      ..headers = {
        'location': [
          'https://team.cloudflareaccess.com/cdn-cgi/access/login/x',
        ],
      };
    await expectLater(
      container.read(mailboxesProvider.future),
      throwsA(anything),
    );
    await pumpEventQueue();
    expect(
      container.read(sessionProvider).value,
      isA<Expired>().having((s) => s.inbox, 'inbox', inbox),
    );
  });

  test(
    'switching mailbox clears the choice and signing out keeps the last inbox',
    () async {
      final fakes = await registerFakes();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(sessionProvider.future);
      await container.read(sessionProvider.notifier).chooseMailbox(null);
      expect(
        container.read(sessionProvider).value,
        isA<SignedIn>().having((s) => s.mailboxId, 'mailboxId', isNull),
      );
      expect(fakes.choices.mailboxId, isNull);
      await container.read(sessionProvider.notifier).signOut();
      expect(
        container.read(sessionProvider).value,
        isA<SignedOut>().having((s) => s.lastInbox, 'lastInbox', inbox),
      );
    },
  );

  test('mailbox summaries carry the inbox unread count', () async {
    final fakes = await registerFakes();
    fakes.server
      ..on(
        'GET',
        '/api/v1/mailboxes',
        (_) => [
          {'id': mailboxId, 'email': mailboxId},
        ],
      )
      ..on(
        'GET',
        '$mailboxPathPrefix/folders',
        (_) => [
          {'id': 'inbox', 'name': 'Inbox', 'unreadCount': 3},
        ],
      );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final list = await container.read(mailboxesProvider.future);
    expect(list.single.mailbox.email, mailboxId);
    expect(list.single.unread, 3);
  });
}
