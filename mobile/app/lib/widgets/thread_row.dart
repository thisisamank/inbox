import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../models/thread.dart';
import '../utils/format.dart';

class ThreadRow extends StatelessWidget {
  const ThreadRow({
    super.key,
    required this.thread,
    this.onTap,
    this.onLongPress,
    this.highlight = const [],
    this.folderBadge,
  });

  final ThreadSummary thread;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<String> highlight;
  final String? folderBadge;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final unread = thread.unread;
    final weight = unread ? FontWeight.w600 : FontWeight.w400;
    final names = participantNames(thread.participants);
    final snippet = snippetText(thread.snippet);
    final subject = thread.subject.trim().isEmpty
        ? '(no subject)'
        : thread.subject;

    return Semantics(
      label: '${unread ? 'Unread. ' : ''}$names. $subject',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: InSpace.gutter,
            vertical: InSpace.rowGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InAvatar(names),
              const SizedBox(width: InSpace.rowGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: names,
                                  style: InType.body.copyWith(
                                    fontWeight: weight,
                                    color: c.ink,
                                  ),
                                ),
                                if (thread.count > 1)
                                  TextSpan(
                                    text: '  ${thread.count}',
                                    style: InType.monoSmall.copyWith(
                                      color: c.ink3,
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: InSpace.s4),
                        Text(
                          formatListDate(context, thread.date),
                          style: InType.caption.copyWith(
                            color: unread ? c.unread : c.ink3,
                            fontWeight: unread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: InSpace.s1),
                    Text.rich(
                      TextSpan(
                        children: inHighlightSpans(
                          subject,
                          highlight,
                          c.accentTint,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: InType.row.copyWith(
                        fontWeight: weight,
                        color: c.ink,
                      ),
                    ),
                    if (snippet.isNotEmpty)
                      Text(
                        snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: InType.meta.copyWith(color: c.ink2),
                      ),
                    if (thread.hasDraft) ...[
                      const SizedBox(height: InSpace.s3),
                      InTag(
                        label: 'Draft ready',
                        icon: Icons.auto_awesome,
                        color: c.agent,
                        background: c.agentTint,
                      ),
                    ],
                    if (folderBadge != null) ...[
                      const SizedBox(height: InSpace.s3),
                      InTag.outline(label: folderBadge!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
