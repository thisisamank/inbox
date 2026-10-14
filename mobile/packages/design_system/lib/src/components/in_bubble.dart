import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class InBubble extends StatelessWidget {
  const InBubble({super.key, required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    const round = Radius.circular(InRadius.bubble);
    const tight = Radius.circular(4);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            InSpace.gutter,
            0,
            InSpace.gutter,
            InSpace.s5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: InSpace.s5,
          ),
          decoration: BoxDecoration(
            color: mine ? c.ink : c.surface2,
            borderRadius: BorderRadius.only(
              topLeft: round,
              topRight: round,
              bottomLeft: mine ? round : tight,
              bottomRight: mine ? tight : round,
            ),
          ),
          child: SelectableText(
            text,
            style: InType.row.copyWith(
              color: mine ? c.surface : c.ink,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
