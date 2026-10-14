import 'package:agentic_inbox/app/inbox_app.dart';
import 'package:agentic_inbox/screens/mail/inbox_screen.dart';
import 'package:agentic_inbox/screens/way_in/sign_in_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  tearDown(tearDownFakes);

  testWidgets(
    'signed out, the app opens on sign-in with the last inbox filled in',
    (tester) async {
      await registerFakes(signedIn: false);
      await tester.pumpWidget(const ProviderScope(child: InboxApp()));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('inbox.example.dev'), findsOneWidget);
      expect(find.text('Sign in with Cloudflare Access'), findsOneWidget);
    },
  );

  testWidgets('signed in without a mailbox, the app asks for one', (
    tester,
  ) async {
    final fakes = await registerFakes(mailbox: null);
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
          {'id': 'inbox', 'name': 'Inbox', 'unreadCount': 2},
        ],
      );
    await tester.pumpWidget(const ProviderScope(child: InboxApp()));
    await tester.pumpAndSettle();
    expect(find.text('Mailboxes'), findsOneWidget);
    expect(find.text(mailboxId), findsOneWidget);
    expect(find.text('2 unread'), findsOneWidget);
  });

  testWidgets('the inbox lists threads with unread state and the draft tag', (
    tester,
  ) async {
    final fakes = await registerFakes();
    fakes.server
      ..on(
        'GET',
        '$mailboxPathPrefix/folders',
        (_) => [
          {'id': 'inbox', 'name': 'Inbox', 'unreadCount': 1},
        ],
      )
      ..on(
        'GET',
        '$mailboxPathPrefix/emails',
        (_) => {
          'emails': [
            threadJson(
              id: 'a',
              subject: 'Q4 contract',
              hasDraft: true,
              count: 3,
            ),
            threadJson(
              id: 'b',
              subject: 'Payout',
              read: true,
              sender: 'stripe@stripe.com',
            ),
          ],
          'totalCount': 2,
        },
      );
    await tester.pumpWidget(wrap(const InboxScreen(mailboxId: mailboxId)));
    await tester.pumpAndSettle();
    expect(find.text('Q4 contract'), findsOneWidget);
    expect(find.text('Payout'), findsOneWidget);
    expect(find.text('Draft ready'), findsOneWidget);
    expect(find.text('Hi Aman'), findsNWidgets(2));
    expect(find.text('Compose'), findsOneWidget);
  });

  testWidgets('an empty inbox explains how mail arrives', (tester) async {
    final fakes = await registerFakes();
    fakes.server
      ..on('GET', '$mailboxPathPrefix/folders', (_) => <Object>[])
      ..on(
        'GET',
        '$mailboxPathPrefix/emails',
        (_) => {'emails': <Object>[], 'totalCount': 0},
      );
    await tester.pumpWidget(wrap(const InboxScreen(mailboxId: mailboxId)));
    await tester.pumpAndSettle();
    expect(find.text('No mail yet'), findsOneWidget);
    expect(
      find.textContaining('Send a test email to $mailboxId'),
      findsOneWidget,
    );
  });
}
