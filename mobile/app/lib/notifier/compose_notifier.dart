import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../models/compose.dart';
import '../models/email.dart';
import '../models/mailbox.dart';
import '../models/thread.dart';
import 'folders_notifier.dart';
import 'mailboxes_notifier.dart';
import 'threads_notifier.dart';

part 'compose_notifier.g.dart';

const maxAttachmentBytes = 20 * 1024 * 1024;

@immutable
class ComposeState {
  const ComposeState({
    this.original,
    this.attachments = const [],
    this.busy = false,
    this.error,
  });

  final EmailMessage? original;
  final List<OutgoingAttachment> attachments;
  final bool busy;
  final String? error;

  ComposeState copyWith({
    EmailMessage? original,
    List<OutgoingAttachment>? attachments,
    bool? busy,
    String? Function()? error,
  }) => ComposeState(
    original: original ?? this.original,
    attachments: attachments ?? this.attachments,
    busy: busy ?? this.busy,
    error: error == null ? this.error : error(),
  );
}

String? validateCompose(
  ComposeFields fields,
  List<OutgoingAttachment> attachments,
) {
  final to = splitAddresses(fields.to);
  if (to.isEmpty) return 'Add at least one recipient.';
  final bad = [
    ...to,
    ...splitAddresses(fields.cc),
    ...splitAddresses(fields.bcc),
  ].where((a) => !isValidAddress(a)).toList();
  if (bad.isNotEmpty) return 'Check these addresses: ${bad.join(', ')}';
  final size = attachments.fold<int>(0, (s, a) => s + a.bytes.length);
  if (size > maxAttachmentBytes) {
    return 'Attachments are larger than ${formatBytes(maxAttachmentBytes)}.';
  }
  return null;
}

({String html, String text}) composeContent({
  required String body,
  required String signature,
  required ComposeMode mode,
  EmailMessage? quoting,
}) {
  final sig = signature.trim();
  var html = '<div>${textToHtml(body)}</div>${signatureHtml(sig)}';
  var text = body;
  if (sig.isNotEmpty) text += '\n\n-- \n$sig';
  final q = quoting;
  if (q != null && mode != ComposeMode.compose) {
    if (mode == ComposeMode.forward) {
      html += forwardHtml(q.date, q.sender, q.subject, q.body);
      text += '\n\n${forwardText(q.date, q.sender, q.subject, q.body)}';
    } else {
      html += quotedReplyHtml(q.date, q.sender, q.body);
      text += '\n\n${quotedReplyText(q.date, q.sender, q.body)}';
    }
  }
  return (html: html, text: text.trim());
}

@riverpod
class Compose extends _$Compose {
  @override
  ComposeState build(String mailboxId, ComposeArgs args) {
    final inReplyTo = args.draft?.inReplyTo;
    if (inReplyTo != null && args.original == null) _loadOriginal(inReplyTo);
    return ComposeState(original: args.original);
  }

  bool get quotes =>
      args.draft == null &&
      state.original != null &&
      args.effectiveMode != ComposeMode.compose;

  Future<void> _loadOriginal(String id) async {
    try {
      final original = await mail.email(mailboxId, id);
      if (ref.mounted) state = state.copyWith(original: original);
    } on Object catch (_) {}
  }

  void fail(String message) => state = state.copyWith(error: () => message);

  Future<void> attach() async {
    final picked = await files.pick();
    if (picked.isNotEmpty && ref.mounted) {
      state = state.copyWith(attachments: [...state.attachments, ...picked]);
    }
  }

  void remove(OutgoingAttachment attachment) => state = state.copyWith(
    attachments: [...state.attachments.where((a) => !identical(a, attachment))],
  );

  Future<MailboxDetails> _details() =>
      ref.read(mailboxDetailsProvider(mailboxId).future);

  Future<Outcome?> send(ComposeFields fields) async {
    final problem = validateCompose(fields, state.attachments);
    if (problem != null) {
      fail(problem);
      return null;
    }
    return _run(() async {
      final details = await _details();
      final content = composeContent(
        body: fields.body,
        signature: details.signature,
        mode: args.effectiveMode,
        quoting: quotes ? state.original : null,
      );
      await compose.send(
        mailboxId,
        OutgoingEmail(
          to: splitAddresses(fields.to),
          cc: splitAddresses(fields.cc),
          bcc: splitAddresses(fields.bcc),
          from: details.from,
          subject: fields.subject.trim().isEmpty
              ? '(no subject)'
              : fields.subject.trim(),
          html: content.html,
          text: content.text,
          attachments: state.attachments,
        ),
        mode: args.effectiveMode,
        originalId: state.original?.id ?? args.draft?.inReplyTo,
      );
      final draftId = args.draft?.id;
      if (draftId != null) {
        try {
          await compose.discard(mailboxId, draftId);
        } on ApiFailure catch (_) {}
      }
      return const Outcome('Sent');
    });
  }

  Future<Outcome?> saveDraft(ComposeFields fields) => _run(() async {
    final details = await _details();
    final original = state.original;
    await compose.saveDraft(
      mailboxId,
      DraftInput(
        to: fields.to.trim(),
        cc: fields.cc.trim(),
        bcc: fields.bcc.trim(),
        subject: fields.subject.trim(),
        body: composeContent(
          body: fields.body,
          signature: details.signature,
          mode: args.effectiveMode,
          quoting: quotes ? original : null,
        ).html,
        inReplyTo: original?.id ?? args.draft?.inReplyTo,
        threadId: original?.threadId ?? args.draft?.threadId,
        draftId: args.draft?.id,
      ),
    );
    return Outcome(
      state.attachments.isEmpty
          ? 'Draft saved'
          : 'Draft saved without attachments',
    );
  });

  Future<Outcome?> discard() => _run(() async {
    final draftId = args.draft?.id;
    if (draftId != null) await compose.discard(mailboxId, draftId);
    return const Outcome('Draft discarded');
  });

  Future<Outcome?> _run(Future<Outcome> Function() action) async {
    state = state.copyWith(busy: true, error: () => null);
    final result = await AsyncValue.guard(action);
    if (!ref.mounted) return result.value;
    if (result.hasError) {
      state = state.copyWith(busy: false, error: () => '${result.error}');
      return null;
    }
    ref
      ..invalidate(threadsProvider)
      ..invalidate(foldersProvider(mailboxId));
    state = state.copyWith(busy: false);
    return result.value;
  }
}
