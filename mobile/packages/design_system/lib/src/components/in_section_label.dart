import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class InSectionLabel extends StatelessWidget {
  const InSectionLabel(
    this.label, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      InSpace.gutter,
      18,
      InSpace.gutter,
      InSpace.s3,
    ),
  });

  final String label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(
      label.toUpperCase(),
      style: InType.overline.copyWith(color: InColors.of(context).ink3),
    ),
  );
}
