import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../models/thread.dart';

void showOutcome(
  BuildContext context,
  Outcome outcome, {
  VoidCallback? afterUndo,
}) {
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  final undo = outcome.undo;
  messenger.showSnackBar(
    SnackBar(
      content: Text(outcome.message),
      action: undo == null
          ? null
          : SnackBarAction(
              label: 'Undo',
              onPressed: () =>
                  undo().then((_) => afterUndo?.call()).catchError((Object e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Undo failed: $e')),
                    );
                  }),
            ),
    ),
  );
}

void showProblem(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
}

Future<bool> confirmDeleteForever(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete forever?'),
      content: const Text(
        'This removes the conversation and its attachments. You cannot undo this.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: InColors.of(context).danger,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
