import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

class InSwipeBackground extends StatelessWidget {
  const InSwipeBackground({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final Color color;
  final IconData icon;
  final String label;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, color: Colors.white),
      const SizedBox(width: InSpace.s4),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: InSpace.s8),
        child: Align(
          alignment: trailing ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: trailing ? children.reversed.toList() : children,
          ),
        ),
      ),
    );
  }
}
