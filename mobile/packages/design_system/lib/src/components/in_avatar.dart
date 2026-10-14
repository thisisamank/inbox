import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class InAvatar extends StatelessWidget {
  const InAvatar(this.label, {super.key, this.size = 40});

  final String label;
  final double size;

  static Color toneFor(String label) {
    final text = label.trim();
    final hash = text.codeUnits.fold<int>(
      0,
      (a, b) => (a * 31 + b) & 0x7fffffff,
    );
    return InColors.avatarTones[hash % InColors.avatarTones.length];
  }

  static String initialOf(String label) {
    final text = label.trim();
    return text.isEmpty ? '?' : text.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CircleAvatar(
      radius: size / 2,
      backgroundColor: toneFor(label),
      child: Text(
        initialOf(label),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.38,
        ),
      ),
    ),
  );
}
