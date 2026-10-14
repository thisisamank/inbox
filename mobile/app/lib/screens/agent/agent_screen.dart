import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../models/agent_chat.dart';
import '../../models/compose.dart';
import '../../models/thread.dart';
import '../../notifier/agent_chat_notifier.dart';
import '../../notifier/conversation_notifier.dart';
import '../../widgets/agent_parts.dart';
import '../../widgets/feedback.dart';

const _suggestions = [
  'Summarize my unread mail',
  'Draft replies for today',
  'Find invoices from this month',
];

class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key, required this.mailboxId});

  final String mailboxId;

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  AgentChat get _chat => ref.read(agentChatProvider(widget.mailboxId).notifier);

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    if (_chat.send(text ?? _input.text)) _input.clear();
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear the conversation?'),
        content: const Text(
          'This removes the chat history for this mailbox on every device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) _chat.clear();
  }

  Future<void> _openDraft(String draftId) async {
    try {
      final draft = await ref.read(
        emailProvider(widget.mailboxId, draftId).future,
      );
      if (!mounted) return;
      final outcome = await context.push<Outcome>(
        Routes.compose,
        extra: ComposeArgs(draft: draft),
      );
      if (outcome != null && mounted) showOutcome(context, outcome);
    } on Exception catch (_) {
      if (mounted) {
        showProblem(context, 'This draft was already sent or discarded.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final chat = ref.watch(agentChatProvider(widget.mailboxId));
    ref.listen(
      agentChatProvider(widget.mailboxId).select((s) => s.messages.length),
      (_, _) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      },
    );
    final messages = chat.messages.reversed.toList();
    final online = chat.connection == AgentConnection.online;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: c.line),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: InTitle('Agent', subtitle: widget.mailboxId),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              tooltip: 'Clear conversation',
              onPressed: _clear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          if (chat.connection == AgentConnection.offline)
            MaterialBanner(
              content: const Text('The agent is offline. Retrying…'),
              actions: [
                TextButton(
                  onPressed: _chat.reconnectNow,
                  child: const Text('Retry now'),
                ),
              ],
            ),
          Expanded(
            child: !chat.historyLoaded && chat.error == null
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const InEmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Ask about this inbox',
                    body:
                        'The agent can read, search and organize mail, and it drafts replies. It never sends mail itself.',
                  )
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: InSpace.rowGap,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => AgentMessage(
                      message: messages[i],
                      onOpenDraft: _openDraft,
                    ),
                  ),
          ),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpace.gutter,
                InSpace.s2,
                InSpace.gutter,
                InSpace.s2,
              ),
              child: Text(
                chat.error!,
                style: InType.meta.copyWith(color: c.danger),
              ),
            ),
          if (!chat.streaming && online)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: InSpace.gutter,
                  vertical: InSpace.s2,
                ),
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: InSpace.s4),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(_suggestions[i], style: InType.meta),
                  side: BorderSide(color: c.line),
                  backgroundColor: c.surface,
                  onPressed: () => _send(_suggestions[i]),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  InSpace.s6,
                  InSpace.s5,
                  InSpace.s6,
                  InSpace.s5,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 5,
                        enabled: online,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: online
                              ? 'Ask about this inbox…'
                              : 'Connecting…',
                          border: border,
                          enabledBorder: border,
                          focusedBorder: border.copyWith(
                            borderSide: BorderSide(color: c.agent, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: InSpace.gutter,
                            vertical: InSpace.rowGap,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: InSpace.s4),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: c.agent,
                        foregroundColor: c.surface,
                        minimumSize: const Size(InSpace.touch, InSpace.touch),
                      ),
                      tooltip: chat.streaming ? 'Stop' : 'Send',
                      onPressed: !online
                          ? null
                          : (chat.streaming ? _chat.stop : _send),
                      icon: Icon(
                        chat.streaming ? Icons.stop : Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
