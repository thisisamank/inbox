import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

const _draftTools = {'draft_reply', 'draft_email'};

class AgentMessage extends StatelessWidget {
  const AgentMessage({
    super.key,
    required this.message,
    required this.onOpenDraft,
  });

  final Json message;
  final ValueChanged<String> onOpenDraft;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final parts = (message['parts'] as List? ?? const [])
        .whereType<Map>()
        .map((p) => p.cast<String, dynamic>())
        .toList();
    if (message['role'] == 'user') {
      return InBubble(text: messageText(message), mine: true);
    }
    final children = <Widget>[];
    for (final p in parts) {
      final tool = toolNameOf(p);
      if (tool != null) {
        children.add(ToolLine(part: p, name: tool));
        final output = p['output'];
        if (_draftTools.contains(tool) &&
            output is Map &&
            output['draftId'] is String) {
          children.add(
            DraftResult(
              output: output.cast<String, dynamic>(),
              onOpen: () => onOpenDraft(output['draftId'] as String),
            ),
          );
        }
      } else if (p['type'] == 'text' &&
          (p['text'] as String? ?? '').trim().isNotEmpty) {
        children.add(InBubble(text: (p['text'] as String).trim(), mine: false));
      }
    }
    if (children.isEmpty &&
        (message['id'] as String? ?? '').startsWith('stream-')) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(
            InSpace.gutter,
            InSpace.s2,
            InSpace.gutter,
            InSpace.s4,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.agent,
                ),
              ),
              const SizedBox(width: InSpace.s5),
              Text('Thinking…', style: InType.meta.copyWith(color: c.ink3)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

String toolDetail(Object? input) {
  if (input is! Map || input.isEmpty) return '';
  return input.entries
      .where((e) => e.value is String || e.value is num || e.value is bool)
      .take(2)
      .map((e) {
        final v = e.value;
        return '${e.key}=${v is String && v.length > 24 ? '${v.substring(0, 24)}…' : v}';
      })
      .join(' · ');
}

class ToolLine extends StatelessWidget {
  const ToolLine({super.key, required this.part, required this.name});

  final Json part;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final state = part['state'] as String? ?? '';
    final failed = state == 'output-error' || state == 'output-denied';
    final done = state == 'output-available';
    final detail = toolDetail(part['input']);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        InSpace.gutter,
        0,
        InSpace.gutter,
        InSpace.s4,
      ),
      child: Row(
        children: [
          if (done || failed)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: failed ? c.danger : c.ok,
                shape: BoxShape.circle,
              ),
            )
          else
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: c.ink3),
            ),
          const SizedBox(width: InSpace.s4),
          Expanded(
            child: Text(
              [
                name,
                if (detail.isNotEmpty) detail,
                if (failed) (part['errorText'] as String? ?? 'failed'),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: InType.monoSmall.copyWith(
                color: failed ? c.danger : c.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DraftResult extends StatelessWidget {
  const DraftResult({super.key, required this.output, required this.onOpen});

  final Json output;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final draft =
        (output['draft'] as Map?)?.cast<String, dynamic>() ?? const {};
    final subject = draft['subject'] as String? ?? '';
    final to = draft['to'] as String? ?? '';
    final body = htmlToPlainText(draft['body'] as String? ?? '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        InSpace.gutter,
        0,
        InSpace.gutter,
        InSpace.rowGap,
      ),
      child: InAgentCard(
        title: subject.isEmpty ? 'Draft saved' : 'Draft · $subject',
        children: [
          if (to.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpace.s6,
                InSpace.s5,
                InSpace.s6,
                0,
              ),
              child: Text(
                'To $to',
                style: InType.caption.copyWith(color: c.ink3),
              ),
            ),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(InSpace.s6),
              child: Text(
                body,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: InType.row.copyWith(color: c.ink, height: 1.5),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InSpace.s6,
              0,
              InSpace.s6,
              InSpace.s6,
            ),
            child: FilledButton(
              onPressed: onOpen,
              child: const Text('Review & send'),
            ),
          ),
        ],
      ),
    );
  }
}
