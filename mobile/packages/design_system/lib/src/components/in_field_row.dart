import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

InputDecoration inBareField(String hint) => InputDecoration(
  hintText: hint,
  filled: false,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(vertical: 14),
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
);

class InFieldRow extends StatelessWidget {
  const InFieldRow({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: InSpace.gutter),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(label, style: InType.row.copyWith(color: c.ink3)),
              ),
              Expanded(child: child),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
