const systemFolderOrder = [
  'inbox',
  'draft',
  'sent',
  'archive',
  'spam',
  'trash',
];

final _style = RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false);
final _script = RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false);
final _openStyle = RegExp(r'<style[^>]*>[\s\S]*', caseSensitive: false);
final _tag = RegExp(r'<[^>]*>');
final _partialTag = RegExp(r'<[^>]*$');
final _space = RegExp(r'\s+');
final _decimalEntity = RegExp(r'&#(\d+);');
final _hexEntity = RegExp(r'&#x([0-9a-f]+);', caseSensitive: false);
const _namedEntities = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&apos;': "'",
  '&nbsp;': ' ',
};

String decodeEntities(String input) {
  var text = input
      .replaceAllMapped(
        _decimalEntity,
        (m) => String.fromCharCode(int.parse(m[1]!)),
      )
      .replaceAllMapped(
        _hexEntity,
        (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
      );
  _namedEntities.forEach((k, v) => text = text.replaceAll(k, v));
  return text;
}

String snippetText(String raw, {int maxLength = 140}) {
  var text = raw
      .replaceAll(_style, '')
      .replaceAll(_openStyle, '')
      .replaceAll(_tag, ' ')
      .replaceAll(_partialTag, '');
  text = decodeEntities(text).replaceAll(_space, ' ').trim();
  return text.length > maxLength ? '${text.substring(0, maxLength)}…' : text;
}

String participantNames(String participants) {
  final names = <String>[];
  for (final p in participants.split(',')) {
    final name = p.trim().split('@').first;
    if (name.isNotEmpty && !names.contains(name)) names.add(name);
  }
  if (names.isEmpty) return '(unknown sender)';
  if (names.length <= 3) return names.join(', ');
  return '${names.take(2).join(', ')} +${names.length - 2}';
}

final _htmlTag = RegExp(
  r'<(html|body|div|p|br|table|span|a|img|b|i|strong|em|ul|ol|li|h[1-6]|blockquote|font)\b',
  caseSensitive: false,
);
final _remoteImage = RegExp(
  r'''<img\b[^>]*\bsrc\s*=\s*["']?\s*https?:''',
  caseSensitive: false,
);

bool looksLikeHtml(String body) => _htmlTag.hasMatch(body);

bool hasRemoteImages(String html) => _remoteImage.hasMatch(html);

String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

String bodyToHtml(String body) => looksLikeHtml(body)
    ? body
    : '<div style="white-space: pre-wrap">${escapeHtml(body)}</div>';

String rewriteInlineImages(String html, Map<String, String> urlByContentId) {
  var result = html;
  urlByContentId.forEach((rawCid, url) {
    final cid = rawCid.startsWith('<') && rawCid.endsWith('>')
        ? rawCid.substring(1, rawCid.length - 1)
        : rawCid;
    result = result.replaceAll(
      RegExp('cid:${RegExp.escape(cid)}', caseSensitive: false),
      url,
    );
  });
  return result;
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String htmlToPlainText(String html) {
  if (!looksLikeHtml(html)) return html.trim();
  final text = html
      .replaceAll(_style, '')
      .replaceAll(_script, '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll(_tag, '');
  return decodeEntities(text).replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

String textToHtml(String text) => escapeHtml(text).replaceAll('\n', '<br>');

String prefixedSubject(String subject, String prefix) {
  final expected = '$prefix: ';
  return subject.startsWith(expected) ? subject : '$expected$subject';
}

final _addressPattern = RegExp(
  r"^[^\s@<>(),;:]+@[^\s@<>(),;:]+\.[^\s@<>(),;:]+$",
);

List<String> splitAddresses(String? value) => [
  for (final part in (value ?? '').split(RegExp(r'[,;]')))
    if (part.trim().isNotEmpty) part.trim(),
];

bool isValidAddress(String address) => _addressPattern.hasMatch(address);

({String to, String cc}) replyAllRecipients({
  required String sender,
  required String recipient,
  String? cc,
  required String self,
}) {
  final me = self.toLowerCase();
  final seen = <String>{me};
  final to = <String>[];
  final ccList = <String>[];
  for (final a in [sender, ...splitAddresses(recipient)]) {
    if (seen.add(a.toLowerCase())) to.add(a);
  }
  for (final a in splitAddresses(cc)) {
    if (seen.add(a.toLowerCase())) ccList.add(a);
  }
  return (to: to.join(', '), cc: ccList.join(', '));
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String composeDate(DateTime? date) {
  if (date == null) return 'an earlier date';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}, ${date.year}, $hour:$minute $period';
}

String quotedReplyHtml(DateTime? date, String sender, String body) {
  if (body.isEmpty) return '';
  final quoted = escapeHtml(htmlToPlainText(body)).replaceAll('\n', '<br>');
  return '<br><blockquote style="border-left: 2px solid #ccc; margin: 0; padding-left: 1em; color: #666;">'
      'On ${composeDate(date)}, ${escapeHtml(sender)} wrote:<br><br>$quoted</blockquote>';
}

String quotedReplyText(DateTime? date, String sender, String body) {
  if (body.isEmpty) return '';
  final quoted = htmlToPlainText(
    body,
  ).split('\n').map((l) => '> $l').join('\n');
  return 'On ${composeDate(date)}, $sender wrote:\n\n$quoted';
}

String forwardHtml(
  DateTime? date,
  String sender,
  String subject,
  String body,
) =>
    '<div style="border: 1px solid #ddd; padding: 1em; background-color: #f9f9f9; margin: 1em 0;">'
    '<strong>Forwarded message:</strong><br><strong>From:</strong> ${escapeHtml(sender)}<br>'
    '<strong>Date:</strong> ${composeDate(date)}<br><strong>Subject:</strong> ${escapeHtml(subject)}<br><br>'
    '${escapeHtml(htmlToPlainText(body)).replaceAll('\n', '<br>')}</div>';

String forwardText(
  DateTime? date,
  String sender,
  String subject,
  String body,
) =>
    '---------- Forwarded message ----------\nFrom: $sender\nDate: ${composeDate(date)}\nSubject: $subject\n\n'
    '${htmlToPlainText(body)}';

String signatureHtml(String signatureText) => signatureText.trim().isEmpty
    ? ''
    : '<div style="border-top: 1px solid #ccc; margin-top: 16px; padding-top: 12px;">${textToHtml(signatureText.trim())}</div>';
