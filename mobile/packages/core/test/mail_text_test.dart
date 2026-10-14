import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snippetText strips HTML, styles and entities', () {
    expect(
      snippetText(
        '<style>p{color:red}</style><p>Hi&nbsp;Aman &amp; team</p><div>Next',
      ),
      'Hi Aman & team Next',
    );
    expect(snippetText('<p>cut off <a href="x'), 'cut off');
    expect(snippetText('caf&#233; &#x2014; ok'), 'café — ok');
    expect(snippetText('a' * 200, maxLength: 10), '${'a' * 10}…');
  });

  test('participantNames dedupes and truncates like the web list', () {
    expect(
      participantNames('priya@x.com, aman@akxr.in,priya@x.com'),
      'priya, aman',
    );
    expect(participantNames('a@x, b@x, c@x, d@x'), 'a, b +2');
    expect(participantNames(''), '(unknown sender)');
  });

  test('bodyToHtml escapes plain text and keeps HTML', () {
    expect(
      bodyToHtml('a < b\nnext'),
      '<div style="white-space: pre-wrap">a &lt; b\nnext</div>',
    );
    expect(bodyToHtml('<p>hi</p>'), '<p>hi</p>');
  });

  test('rewriteInlineImages maps cid references with or without brackets', () {
    final out = rewriteInlineImages(
      '<img src="cid:logo@x"><img src="CID:pic.1">',
      {'<logo@x>': 'https://h/a1', 'pic.1': 'https://h/a2'},
    );
    expect(out, '<img src="https://h/a1"><img src="https://h/a2">');
  });

  test('hasRemoteImages detects only http images', () {
    expect(
      hasRemoteImages('<img alt="x" src="https://t.example/p.gif">'),
      isTrue,
    );
    expect(hasRemoteImages("<IMG SRC='http://x/y'>"), isTrue);
    expect(hasRemoteImages('<img src="cid:abc">'), isFalse);
  });

  test('replyAllRecipients drops self and duplicates', () {
    final r = replyAllRecipients(
      sender: 'priya@vendor.com',
      recipient: 'Aman@akxr.in, legal@vendor.com',
      cc: 'priya@vendor.com; ops@vendor.com',
      self: 'aman@akxr.in',
    );
    expect(r.to, 'priya@vendor.com, legal@vendor.com');
    expect(r.cc, 'ops@vendor.com');
  });

  test('address helpers split on comma and semicolon and validate', () {
    expect(splitAddresses(' a@x.dev ; b@y.dev,, '), ['a@x.dev', 'b@y.dev']);
    expect(isValidAddress('a@x.dev'), isTrue);
    expect(isValidAddress('Priya <a@x.dev>'), isFalse);
  });

  test('prefixedSubject does not stack prefixes', () {
    expect(prefixedSubject('Q4', 'Re'), 'Re: Q4');
    expect(prefixedSubject('Re: Q4', 'Re'), 'Re: Q4');
    expect(prefixedSubject('Re: Q4', 'Fwd'), 'Fwd: Re: Q4');
  });

  test('htmlToPlainText keeps paragraph breaks and drops scripts', () {
    expect(
      htmlToPlainText('<p>Hi Priya,</p><p>Friday works &amp; ok.<br>Aman</p>'),
      'Hi Priya,\n\nFriday works & ok.\nAman',
    );
    expect(htmlToPlainText('<p>x</p><script>steal()</script>'), 'x');
  });

  test('quotedReplyHtml escapes the sender and the quoted body', () {
    final html = quotedReplyHtml(
      DateTime(2026, 10, 13, 16, 52),
      'Priya <p@x.dev>',
      '<p>a &lt; b</p>',
    );
    expect(
      html,
      contains('On Tue, Oct 13, 2026, 4:52 PM, Priya &lt;p@x.dev&gt; wrote:'),
    );
    expect(html, contains('a &lt; b'));
  });

  test('parseInboxUrl accepts bare hosts and strips paths', () {
    expect(
      parseInboxUrl('inbox.example.workers.dev').toString(),
      'https://inbox.example.workers.dev',
    );
    expect(
      parseInboxUrl(' https://inbox.example.dev/mail/x ').toString(),
      'https://inbox.example.dev',
    );
    expect(parseInboxUrl(''), isNull);
    expect(parseInboxUrl('not a url'), isNull);
    expect(parseInboxUrl('ftp://x.dev'), isNull);
  });
}
