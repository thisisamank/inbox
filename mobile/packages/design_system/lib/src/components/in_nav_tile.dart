import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class InNavTile extends StatelessWidget {
  const InNavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.count = 0,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
  );

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final color = selected ? c.accent : c.ink;
    return Padding(
      padding: const EdgeInsets.only(right: InSpace.s6),
      child: Material(
        color: selected ? c.accentTint : Colors.transparent,
        shape: _shape,
        child: InkWell(
          onTap: onTap,
          customBorder: _shape,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: InSpace.s8),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: InType.body.copyWith(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (count > 0)
                    Text(
                      '$count',
                      style: InType.monoSmall.copyWith(
                        color: selected ? c.accent : c.ink3,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
