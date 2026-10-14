import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/rewrite_notifier.dart';

Future<String?> showRewriteSheet(
  BuildContext context, {
  required String mailboxId,
  required String text,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _RewriteSheet(mailboxId: mailboxId, text: text),
);

class _RewriteSheet extends ConsumerWidget {
  const _RewriteSheet({required this.mailboxId, required this.text});

  final String mailboxId;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = InColors.of(context);
    final rewrite = ref.watch(rewriteProvider(mailboxId, text));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          InSpace.gutter,
          0,
          InSpace.gutter,
          InSpace.gutter,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: c.agent, size: 20),
                  const SizedBox(width: InSpace.s4),
                  Text(
                    'Rewrite with agent',
                    style: InType.subheading.copyWith(color: c.ink),
                  ),
                ],
              ),
              const SizedBox(height: InSpace.rowGap),
              Flexible(
                child: SingleChildScrollView(
                  child: rewrite.result.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: InSpace.s9,
                          ),
                          child: rewrite.error != null
                              ? Text(
                                  rewrite.error!,
                                  style: InType.body.copyWith(color: c.danger),
                                )
                              : Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: c.agent,
                                      ),
                                    ),
                                    const SizedBox(width: InSpace.s5),
                                    Text(
                                      rewrite.sent
                                          ? 'Rewriting…'
                                          : 'Connecting to the agent…',
                                      style: InType.body.copyWith(
                                        color: c.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                        )
                      : SelectableText(
                          rewrite.result,
                          style: InType.body.copyWith(color: c.ink),
                        ),
                ),
              ),
              const SizedBox(height: InSpace.s4),
              Text(
                'This request also appears in the Agent tab.',
                style: InType.caption.copyWith(color: c.ink3),
              ),
              const SizedBox(height: InSpace.rowGap),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: InSpace.s5),
                  Expanded(
                    child: FilledButton(
                      onPressed: rewrite.done
                          ? () => Navigator.pop(context, rewrite.result)
                          : null,
                      child: const Text('Replace'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
