import 'package:api/api.dart' show attachmentPathFor;
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../models/compose.dart';
import '../../models/email.dart';
import '../../models/mailbox.dart';
import '../../models/thread.dart';
import '../../notifier/conversation_notifier.dart';
import '../../notifier/folders_notifier.dart';
import '../../widgets/feedback.dart';
import '../../widgets/message_parts.dart';
import '../../widgets/move_sheet.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({
    super.key,
    required this.mailboxId,
    required this.thread,
    required this.folder,
  });

  final String mailboxId;
  final ThreadRef thread;
  final String folder;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _expanded = <String>{};
  final _collapsed = <String>{};
  bool _loadImages = false;
  bool _busy = false;

  Conversation get _conversation =>
      ref.read(conversationProvider(widget.mailboxId, widget.thread).notifier);

  String get _primaryTarget =>
      widget.folder == Folder.archive ? Folder.inbox : Folder.archive;

  String _label(String id) => folderLabel(
    id,
    ref.read(foldersProvider(widget.mailboxId)).value ?? const [],
  );

  bool _isExpanded(EmailMessage m, EmailMessage? latest) =>
      !_collapsed.contains(m.id) &&
      (_expanded.contains(m.id) || !m.read || m.id == latest?.id);

  Future<void> _run(
    Future<Outcome?> Function() action, {
    bool pop = true,
  }) async {
    setState(() => _busy = true);
    try {
      final outcome = await action();
      if (!mounted || outcome == null) return;
      if (pop) {
        Navigator.of(context).pop(outcome);
      } else {
        showOutcome(context, outcome);
      }
    } on Exception catch (e) {
      if (mounted) showProblem(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(String to) => _run(
    () => _conversation.move(from: widget.folder, to: to, label: _label(to)),
  );

  Future<void> _delete() async {
    if (widget.folder != Folder.trash) return _move(Folder.trash);
    if (!await confirmDeleteForever(context)) return;
    await _run(() => _conversation.deleteForever(from: widget.folder));
  }

  Future<void> _chooseFolder() async {
    final to = await showMoveSheet(
      context,
      mailboxId: widget.mailboxId,
      current: widget.folder,
    );
    if (to != null && mounted) await _move(to);
  }

  Future<void> _compose(ComposeArgs args) async {
    final outcome = await context.push<Outcome>(Routes.compose, extra: args);
    if (!mounted) return;
    if (outcome != null) showOutcome(context, outcome);
    await _conversation.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(
      conversationProvider(widget.mailboxId, widget.thread),
    );
    final access = ref.watch(inboxAccessProvider).value;
    final messages = conversation.value;
    final sent =
        messages?.where((m) => !m.isDraft).toList() ?? const <EmailMessage>[];
    final latest = sent.isEmpty ? null : sent.last;

    return Scaffold(
      appBar: AppBar(
        actions: messages == null
            ? null
            : _busy
            ? const [
                Padding(
                  padding: EdgeInsets.all(InSpace.gutter),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ]
            : [
                if (widget.folder != Folder.draft)
                  IconButton(
                    tooltip: _primaryTarget == Folder.archive
                        ? 'Archive'
                        : 'Move to Inbox',
                    onPressed: () => _move(_primaryTarget),
                    icon: Icon(
                      _primaryTarget == Folder.archive
                          ? Icons.archive_outlined
                          : Icons.inbox_outlined,
                    ),
                  ),
                IconButton(
                  tooltip: widget.folder == Folder.trash
                      ? 'Delete forever'
                      : 'Delete',
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: 'Mark as unread',
                  onPressed: () => _run(
                    () => _conversation.markUnread(folder: widget.folder),
                  ),
                  icon: const Icon(Icons.mark_email_unread_outlined),
                ),
                IconButton(
                  tooltip: 'Move to…',
                  onPressed: _chooseFolder,
                  icon: const Icon(Icons.drive_file_move_outline),
                ),
              ],
      ),
      bottomNavigationBar: latest == null
          ? null
          : _ReplyBar(
              latest: latest,
              mailboxId: widget.mailboxId,
              enabled: !_busy,
              onCompose: _compose,
            ),
      body: switch (conversation) {
        AsyncValue(:final error?, hasValue: false) => InFailure(
          error: error,
          onRetry: _conversation.refresh,
        ),
        AsyncValue(hasValue: false) => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncValue(:final value) => RefreshIndicator(
          onRefresh: _conversation.refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: InSpace.s11),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  InSpace.gutter,
                  InSpace.s2,
                  InSpace.gutter,
                  InSpace.rowGap,
                ),
                child: Text(
                  _subject(value!),
                  style: InType.title.copyWith(color: InColors.of(context).ink),
                ),
              ),
              const Divider(),
              for (final m in value)
                if (m.isDraft)
                  DraftCard(
                    message: m,
                    busy: _busy,
                    onDiscard: () => _run(() async {
                      await _conversation.discardDraft(m);
                      return const Outcome('Draft discarded');
                    }, pop: false),
                    onEdit: () => _compose(
                      ComposeArgs(
                        draft: m,
                        original: value
                            .where((x) => x.id == m.inReplyTo)
                            .firstOrNull,
                      ),
                    ),
                    onSend: () => _run(() async {
                      await _conversation.sendDraft(m);
                      return const Outcome('Sent');
                    }, pop: false),
                  )
                else
                  MessageCard(
                    message: m,
                    access: access,
                    attachmentPath: (id) =>
                        attachmentPathFor(widget.mailboxId, m.id, id),
                    expanded: _isExpanded(m, latest),
                    loadImages: _loadImages,
                    onToggle: () => setState(() {
                      if (_isExpanded(m, latest)) {
                        _expanded.remove(m.id);
                        _collapsed.add(m.id);
                      } else {
                        _collapsed.remove(m.id);
                        _expanded.add(m.id);
                      }
                    }),
                    onLoadImages: () => setState(() => _loadImages = true),
                    onShare: (a) => _conversation.shareAttachment(m.id, a),
                  ),
            ],
          ),
        ),
      },
    );
  }

  String _subject(List<EmailMessage> messages) {
    final subject = messages
        .map((m) => m.subject.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    return subject.isEmpty ? '(no subject)' : subject;
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.latest,
    required this.mailboxId,
    required this.enabled,
    required this.onCompose,
  });

  final EmailMessage latest;
  final String mailboxId;
  final bool enabled;
  final ValueChanged<ComposeArgs> onCompose;

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final all = replyAllRecipients(
      sender: latest.sender,
      recipient: latest.recipient,
      cc: latest.cc,
      self: mailboxId,
    );
    final showReplyAll =
        splitAddresses(all.to).length + splitAddresses(all.cc).length > 1;
    Widget button(String label, IconData icon, ComposeMode mode) => Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, InSpace.touch),
        ),
        onPressed: enabled
            ? () => onCompose(ComposeArgs(mode: mode, original: latest))
            : null,
        icon: Icon(icon, size: 18),
        label: Text(label, style: InType.row),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            InSpace.gutter,
            InSpace.s5,
            InSpace.gutter,
            InSpace.s5,
          ),
          child: Row(
            spacing: InSpace.s4,
            children: [
              button('Reply', Icons.reply, ComposeMode.reply),
              if (showReplyAll)
                button('Reply all', Icons.reply_all, ComposeMode.replyAll),
              button('Forward', Icons.forward, ComposeMode.forward),
            ],
          ),
        ),
      ),
    );
  }
}
