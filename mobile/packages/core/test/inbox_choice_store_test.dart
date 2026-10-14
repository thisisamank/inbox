import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the in-memory store keeps the inbox and the mailbox', () async {
    final store = InMemoryInboxChoiceStore();
    await store.rememberInbox(Uri.parse('https://a.dev'));
    await store.chooseMailbox('me@a.dev');
    expect(store.lastInbox.toString(), 'https://a.dev');
    expect(store.mailboxId, 'me@a.dev');
  });
}
