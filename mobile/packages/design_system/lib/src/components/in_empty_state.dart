import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class InEmptyState extends StatelessWidget {
  const InEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: InSpace.s10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: c.ink3),
            const SizedBox(height: InSpace.s7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: InType.heading.copyWith(color: c.ink),
            ),
            if (body != null) ...[
              const SizedBox(height: InSpace.s4),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: InType.row.copyWith(color: c.ink2, fontSize: 15),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: InSpace.s8),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class InFailure extends StatelessWidget {
  const InFailure({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => InEmptyState(
    icon: Icons.cloud_off_outlined,
    title: 'Could not load',
    body: '$error',
    action: OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
  );
}
