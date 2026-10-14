import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminanceRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('the theme builds for both brightnesses with its color extension', () {
    for (final b in Brightness.values) {
      final theme = InTheme.build(b);
      expect(theme.extension<InColors>(), InColors.forBrightness(b));
      expect(theme.colorScheme.primary, InColors.forBrightness(b).accent);
    }
  });

  test('body and secondary text meet 4.5:1 on the surface in both modes', () {
    for (final c in [InColors.light, InColors.dark]) {
      expect(_luminanceRatio(c.ink, c.surface), greaterThanOrEqualTo(4.5));
      expect(_luminanceRatio(c.ink2, c.surface), greaterThanOrEqualTo(4.5));
      expect(_luminanceRatio(c.ink3, c.surface), greaterThanOrEqualTo(4.5));
      expect(_luminanceRatio(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
    }
  });

  test('white swipe labels stay readable on the swipe colors', () {
    expect(
      _luminanceRatio(Colors.white, InColors.swipeArchive),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _luminanceRatio(Colors.white, InColors.swipeDelete),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('avatars pick a stable tone and initial', () {
    expect(InAvatar.toneFor('priya'), InAvatar.toneFor('priya'));
    expect(InAvatar.initialOf('  priya'), 'P');
    expect(InAvatar.initialOf(''), '?');
  });

  test('highlight spans mark every match case-insensitively', () {
    final spans = inHighlightSpans('Q4 vendor contract', [
      'CONTRACT',
      'q4',
    ], Colors.yellow);
    expect(spans.length, 3);
    expect((spans.first as TextSpan).text, 'Q4');
    expect((spans.last as TextSpan).text, 'contract');
  });
}
