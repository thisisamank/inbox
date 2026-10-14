import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

class InTitle extends StatelessWidget {
  const InTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(title),
      if (subtitle != null)
        Text(
          subtitle!,
          overflow: TextOverflow.ellipsis,
          style: InType.monoSmall.copyWith(color: InColors.of(context).ink3),
        ),
    ],
  );
}
