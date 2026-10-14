import 'package:agentic_inbox/models/compose.dart';
import 'package:agentic_inbox/models/email.dart';
import 'package:agentic_inbox/notifier/compose_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

EmailMessage original() => EmailMessage(
  id: 'orig',
  threadId: 't1',
  folderId: 'inbox',
  subject: 'Q4',
  sender: 'priya@vendor.com',
  fromHeader: null,
  recipient: mailboxId,
  cc: null,
  bcc: null,
  date: DateTime(2026, 10, 13, 16, 52),
  read: true,
  body: '<p>Legal signed off.</p>',
  inReplyTo: null,
  attachments: const [],
);

void main() {
  tearDown(tearDownFakes);

  test('validateCompose names bad addresses and the size limit', () {
    const ok = ComposeFields(
      to: 'a@x.dev',
      cc: '',
      bcc: '',
      subject: '',
      body: '',
    );
    expect(validateCompose(ok, const []), isNull);
    expect(
      validateCompose(
        const ComposeFields(to: '', cc: '', bcc: '', subject: '', body: ''),
        const [],
      ),
      'Add at least one recipient.',
    );
    expect(
      validateCompose(
        const ComposeFields(
          to: 'a@x.dev, nope',
          cc: '',
          bcc: '',
          subject: '',
          body: '',
        ),
        const [],
      ),
      'Check these addresses: nope',
    );
    final big = OutgoingAttachment(
      filename: 'big.bin',
      type: 'application/octet-stream',
      bytes: List.filled(maxAttachmentBytes + 1, 0),
    );
    expect(validateCompose(ok, [big]), contains('larger than'));
  });

  test(
    'composeContent adds the signature and quotes only for replies and forwards',
    () {
      final reply = composeContent(
        body: 'Friday works.',
        signature: 'Aman',
        mode: ComposeMode.reply,
        quoting: original(),
      );
      expect(reply.html, startsWith('<div>Friday works.</div>'));
      expect(reply.html, contains('<blockquote'));
      expect(reply.text, contains('-- \nAman'));
      expect(reply.text, contains('> Legal signed off.'));
      final fresh = composeContent(
        body: 'Hi',
        signature: '',
        mode: ComposeMode.compose,
        quoting: original(),
      );
      expect(fresh.html, '<div>Hi</div>');
      final forward = composeContent(
        body: 'FYI',
        signature: '',
        mode: ComposeMode.forward,
        quoting: original(),
      );
      expect(forward.html, contains('Forwarded message'));
    },
  );

  test(
    'a reply goes to the reply endpoint and removes the draft it came from',
    () async {
      final fakes = await registerFakes();
      fakes.server
        ..on(
          'GET',
          mailboxPathPrefix,
          (_) => {
            'id': mailboxId,
            'email': mailboxId,
            'settings': <String, Object>{},
          },
        )
        ..on(
          'POST',
          '$mailboxPathPrefix/emails/orig/reply',
          (_) => {'id': 'n', 'status': 'sent'},
        )
        ..on('DELETE', '$mailboxPathPrefix/emails/d1', (_) => null)
        ..on('GET', '$mailboxPathPrefix/folders', (_) => <Object>[]);
      final draft = EmailMessage(
        id: 'd1',
        threadId: 't1',
        folderId: 'draft',
        subject: 'Re: Q4',
        sender: mailboxId,
        fromHeader: null,
        recipient: 'priya@vendor.com',
        cc: null,
        bcc: null,
        date: null,
        read: true,
        body: 'Friday works.',
        inReplyTo: 'orig',
        attachments: const [],
      );
      final args = ComposeArgs(draft: draft, original: original());
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = composeProvider(mailboxId, args);
      container.listen(provider, (_, _) {});
      final outcome = await container
          .read(provider.notifier)
          .send(
            const ComposeFields(
              to: 'priya@vendor.com',
              cc: '',
              bcc: '',
              subject: 'Re: Q4',
              body: 'Friday works.',
            ),
          );
      expect(outcome?.message, 'Sent');
      expect(
        fakes.server.calls,
        containsAllInOrder([
          'POST $mailboxPathPrefix/emails/orig/reply',
          'DELETE $mailboxPathPrefix/emails/d1',
        ]),
      );
    },
  );
}
