import 'dart:async';

import 'package:api/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../models/email.dart';
import '../models/thread.dart';
import 'folders_notifier.dart';
import 'threads_notifier.dart';

part 'conversation_notifier.g.dart';

@riverpod
class Conversation extends _$Conversation {
  @override
  Future<List<EmailMessage>> build(String mailboxId, ThreadRef thread) async {
    final messages = await mail.conversation(mailboxId, thread);
    unawaited(_markRead(messages));
    return messages;
  }

  Future<void> _markRead(List<EmailMessage> messages) async {
    try {
      await mail.markRead(mailboxId, thread, messages);
      if (!ref.mounted) return;
      ref
        ..invalidate(threadsProvider)
        ..invalidate(foldersProvider(mailboxId));
    } on Object catch (_) {}
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object catch (_) {}
  }

  Future<Outcome> move({
    required String from,
    required String to,
    required String label,
  }) async {
    final ids = await mail.move(mailboxId, thread, from: from, to: to);
    _changed();
    return Outcome(
      'Moved to $label',
      undo: () async {
        await mail.moveIds(mailboxId, ids, from);
        _changed();
      },
    );
  }

  Future<Outcome> deleteForever({required String from}) async {
    await mail.deleteForever(mailboxId, thread, from: from);
    _changed();
    return const Outcome('Deleted forever');
  }

  Future<Outcome> markUnread({required String folder}) async {
    final messages = state.value ?? const [];
    final inFolder = messages
        .where((m) => !m.isDraft && m.folderId == folder)
        .toList();
    final target = inFolder.isNotEmpty ? inFolder.last.id : thread.emailId;
    await mail.setRead(mailboxId, ThreadRef(emailId: target), read: false);
    _changed();
    return const Outcome('Marked as unread');
  }

  Future<void> sendDraft(EmailMessage draft) async {
    await compose.sendDraft(mailboxId, draft);
    _changed();
    await refresh();
  }

  Future<void> discardDraft(EmailMessage draft) async {
    await compose.discard(mailboxId, draft.id);
    _changed();
    await refresh();
  }

  Future<void> shareAttachment(String emailId, Attachment attachment) =>
      mail.shareAttachment(mailboxId, emailId, attachment);

  void _changed() {
    if (!ref.mounted) return;
    ref
      ..invalidate(threadsProvider)
      ..invalidate(foldersProvider(mailboxId));
  }
}

@riverpod
Future<EmailMessage> email(Ref ref, String mailboxId, String emailId) =>
    mail.email(mailboxId, emailId);

@riverpod
Future<AccessSession> inboxAccess(Ref ref) => mail.access();
