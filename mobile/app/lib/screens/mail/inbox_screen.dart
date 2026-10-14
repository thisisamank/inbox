import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../models/compose.dart';
import '../../models/mailbox.dart';
import '../../models/thread.dart';
import '../../notifier/conversation_notifier.dart';
import '../../notifier/folders_notifier.dart';
import '../../notifier/session_notifier.dart';
import '../../notifier/threads_notifier.dart';
import '../../widgets/feedback.dart';
import '../../widgets/folder_drawer.dart';
import '../../widgets/move_sheet.dart';
import '../../widgets/thread_row.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, required this.mailboxId});

  final String mailboxId;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _scroll = ScrollController();

  String get _folder => ref.read(selectedFolderProvider(widget.mailboxId));

  Threads get _threads =>
      ref.read(threadsProvider(widget.mailboxId, _folder).notifier);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _threads.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _label(String id) => folderLabel(
    id,
    ref.read(foldersProvider(widget.mailboxId)).value ?? const [],
  );

  String get _swipeTarget =>
      _folder == Folder.archive ? Folder.inbox : Folder.archive;

  void _selectFolder(String id) {
    Navigator.of(context).pop();
    ref.read(selectedFolderProvider(widget.mailboxId).notifier).select(id);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _compose([ComposeArgs args = const ComposeArgs()]) async {
    final outcome = await context.push<Outcome>(Routes.compose, extra: args);
    if (outcome != null && mounted) showOutcome(context, outcome);
  }

  Future<void> _open(ThreadSummary t) async {
    if (_folder == Folder.draft) {
      try {
        final draft = await ref.read(
          emailProvider(widget.mailboxId, t.id).future,
        );
        if (mounted) await _compose(ComposeArgs(draft: draft));
      } on Exception catch (e) {
        if (mounted) showProblem(context, e);
      }
      return;
    }
    final outcome = await context.push<Outcome>(
      Routes.thread(t.ref, folder: _folder),
    );
    if (outcome != null && mounted) {
      showOutcome(context, outcome, afterUndo: _threads.refresh);
    }
  }

  Future<void> _move(ThreadSummary t, String to) async {
    final threads = _threads;
    try {
      final outcome = await threads.move(t, to: to, label: _label(to));
      if (mounted) showOutcome(context, outcome);
    } on Exception catch (e) {
      if (mounted) showProblem(context, e);
    }
  }

  Future<void> _delete(ThreadSummary t, {bool confirmed = false}) async {
    if (_folder != Folder.trash) return _move(t, Folder.trash);
    if (!confirmed && !await confirmDeleteForever(context)) return;
    final threads = _threads;
    try {
      final outcome = await threads.deleteForever(t);
      if (mounted) showOutcome(context, outcome);
    } on Exception catch (e) {
      if (mounted) showProblem(context, e);
    }
  }

  Future<void> _toggleRead(ThreadSummary t) async {
    try {
      await _threads.toggleRead(t);
    } on Exception catch (e) {
      if (mounted) showProblem(context, e);
    }
  }

  Future<void> _chooseFolder(ThreadSummary t) async {
    final to = await showMoveSheet(
      context,
      mailboxId: widget.mailboxId,
      current: _folder,
    );
    if (to != null && mounted) await _move(t, to);
  }

  Future<void> _newFolder() async {
    Navigator.of(context).pop();
    await showNewFolderDialog(context, mailboxId: widget.mailboxId);
  }

  Future<void> _actions(ThreadSummary t) async {
    final c = InColors.of(context);
    final archive = _swipeTarget == Folder.archive;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                t.unread
                    ? Icons.mark_email_read_outlined
                    : Icons.mark_email_unread_outlined,
              ),
              title: Text(t.unread ? 'Mark as read' : 'Mark as unread'),
              onTap: () => Navigator.pop(context, 'read'),
            ),
            if (_folder != Folder.draft)
              ListTile(
                leading: Icon(
                  archive ? Icons.archive_outlined : Icons.inbox_outlined,
                ),
                title: Text(archive ? 'Archive' : 'Move to Inbox'),
                onTap: () => Navigator.pop(context, 'swipe'),
              ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: const Text('Move to…'),
              onTap: () => Navigator.pop(context, 'move'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: c.danger),
              title: Text(
                _folder == Folder.trash ? 'Delete forever' : 'Delete',
                style: TextStyle(color: c.danger),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'read':
        await _toggleRead(t);
      case 'swipe':
        await _move(t, _swipeTarget);
      case 'move':
        await _chooseFolder(t);
      case 'delete':
        await _delete(t);
    }
  }

  Widget _row(ThreadSummary t) {
    final row = ThreadRow(
      thread: t,
      onTap: () => _open(t),
      onLongPress: () => _actions(t),
    );
    if (_folder == Folder.draft) return row;
    final archive = _swipeTarget == Folder.archive;
    return Dismissible(
      key: ValueKey('${_folder}_${t.id}'),
      background: InSwipeBackground(
        color: InColors.swipeArchive,
        icon: archive ? Icons.archive_outlined : Icons.inbox_outlined,
        label: archive ? 'Archive' : 'Inbox',
        trailing: false,
      ),
      secondaryBackground: InSwipeBackground(
        color: InColors.swipeDelete,
        icon: Icons.delete_outline,
        label: _folder == Folder.trash ? 'Delete forever' : 'Delete',
        trailing: true,
      ),
      confirmDismiss: (direction) async =>
          direction == DismissDirection.startToEnd ||
          _folder != Folder.trash ||
          await confirmDeleteForever(context),
      onDismissed: (direction) => direction == DismissDirection.startToEnd
          ? _move(t, _swipeTarget)
          : _delete(t, confirmed: true),
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(selectedFolderProvider(widget.mailboxId));
    final folders =
        ref.watch(foldersProvider(widget.mailboxId)).value ?? const <Folder>[];
    final threads = ref.watch(threadsProvider(widget.mailboxId, folder));
    final name = folderLabel(folder, folders);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: InTitle(name, subtitle: widget.mailboxId),
      ),
      drawer: FolderDrawer(
        mailboxId: widget.mailboxId,
        folders: folders,
        selected: folder,
        onSelect: _selectFolder,
        onNewFolder: _newFolder,
        onSwitchMailbox: () {
          Navigator.of(context).pop();
          ref.read(sessionProvider.notifier).chooseMailbox(null);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Compose'),
      ),
      body: switch (threads) {
        AsyncValue(:final error?, hasValue: false) => InFailure(
          error: error,
          onRetry: _threads.refresh,
        ),
        AsyncValue(hasValue: false) => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncValue(:final value) => RefreshIndicator(
          onRefresh: _threads.refresh,
          child: value!.threads.isEmpty
              ? LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: box.maxHeight,
                      child: InEmptyState(
                        icon: Icons.inbox_outlined,
                        title: folder == Folder.inbox
                            ? 'No mail yet'
                            : 'Nothing in $name',
                        body: folder == Folder.inbox
                            ? 'Send a test email to ${widget.mailboxId}. It shows up here within a minute.'
                            : null,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: value.threads.length + (value.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) => i < value.threads.length
                      ? _row(value.threads[i])
                      : const Padding(
                          padding: EdgeInsets.all(InSpace.s8),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
        ),
      },
    );
  }
}
