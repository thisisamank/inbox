import 'package:flutter/material.dart';

@immutable
class InColors extends ThemeExtension<InColors> {
  const InColors({
    required this.surface,
    required this.surface2,
    required this.line,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.accent,
    required this.onAccent,
    required this.accentTint,
    required this.unread,
    required this.ok,
    required this.danger,
    required this.agent,
    required this.agentTint,
  });

  static const light = InColors(
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF5F4F1),
    line: Color(0xFFE3E1DC),
    ink: Color(0xFF1A1A19),
    ink2: Color(0xFF5C5A55),
    ink3: Color(0xFF75726C),
    accent: Color(0xFFC2410C),
    onAccent: Color(0xFFFFFFFF),
    accentTint: Color(0xFFFDEBDD),
    unread: Color(0xFF1D4ED8),
    ok: Color(0xFF15803D),
    danger: Color(0xFFB91C1C),
    agent: Color(0xFF6D28D9),
    agentTint: Color(0xFFEFE9FB),
  );

  static const dark = InColors(
    surface: Color(0xFF1C1C1B),
    surface2: Color(0xFF252524),
    line: Color(0xFF33322F),
    ink: Color(0xFFF1EFEA),
    ink2: Color(0xFFB3B0A8),
    ink3: Color(0xFF908D86),
    accent: Color(0xFFF97316),
    onAccent: Color(0xFF1A1A19),
    accentTint: Color(0xFF3A2414),
    unread: Color(0xFF7AA2FF),
    ok: Color(0xFF4ADE80),
    danger: Color(0xFFF87171),
    agent: Color(0xFFB79CFF),
    agentTint: Color(0xFF2A2340),
  );

  static const Color swipeArchive = Color(0xFF15803D);
  static const Color swipeDelete = Color(0xFFB91C1C);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color paperInk = Color(0xFF1A1A19);

  static const List<Color> avatarTones = [
    Color(0xFFC2410C),
    Color(0xFF1D4ED8),
    Color(0xFF0F766E),
    Color(0xFF7C3AED),
    Color(0xFFB45309),
    Color(0xFFBE185D),
    Color(0xFF15803D),
    Color(0xFF475569),
  ];

  final Color surface;
  final Color surface2;
  final Color line;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color accent;
  final Color onAccent;
  final Color accentTint;
  final Color unread;
  final Color ok;
  final Color danger;
  final Color agent;
  final Color agentTint;

  static InColors of(BuildContext context) =>
      Theme.of(context).extension<InColors>() ?? light;

  static InColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  InColors copyWith() => this;

  @override
  InColors lerp(InColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}
