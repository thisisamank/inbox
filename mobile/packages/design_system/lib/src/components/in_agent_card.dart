import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class InAgentCard extends StatelessWidget {
  const InAgentCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: c.agent),
        borderRadius: BorderRadius.circular(InRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.agentTint,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(InRadius.card - 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: InSpace.s6,
                vertical: InSpace.s5,
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: c.agent),
                  const SizedBox(width: InSpace.s4),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InType.meta.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.agent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
