import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class InTag extends StatelessWidget {
  const InTag({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.background,
  });

  const InTag.outline({super.key, required this.label})
    : icon = null,
      color = null,
      background = null;

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final ink = color ?? c.ink2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: background == null ? Border.all(color: c.line) : null,
        borderRadius: BorderRadius.circular(InRadius.tag),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: InSpace.s4,
          vertical: InSpace.s1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: ink),
              const SizedBox(width: InSpace.s2),
            ],
            Text(label, style: InType.caption.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}
