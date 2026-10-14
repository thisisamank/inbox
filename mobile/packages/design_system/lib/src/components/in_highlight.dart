import 'package:flutter/painting.dart';

List<InlineSpan> inHighlightSpans(
  String text,
  List<String> terms,
  Color background,
) {
  final words = terms
      .where((t) => t.trim().isNotEmpty)
      .map(RegExp.escape)
      .toList();
  if (words.isEmpty) return [TextSpan(text: text)];
  final pattern = RegExp(words.join('|'), caseSensitive: false);
  final spans = <InlineSpan>[];
  var start = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > start) {
      spans.add(TextSpan(text: text.substring(start, m.start)));
    }
    spans.add(
      TextSpan(
        text: m[0],
        style: TextStyle(backgroundColor: background),
      ),
    );
    start = m.end;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return spans;
}
