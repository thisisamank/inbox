import 'dart:convert';

import 'package:api/api.dart';
import 'package:core/core.dart';

import '../models/compose.dart';
import '../models/email.dart';
import 'mailbox_repository.dart';

class ComposeRepository {
  ComposeRepository(this._client, this._mailboxes);

  final ApiClient _client;
  final MailboxRepository _mailboxes;

  Future<void> send(
    String mailboxId,
    OutgoingEmail email, {
    ComposeMode mode = ComposeMode.compose,
    String? originalId,
  }) {
    final body = email.toJson();
    if (originalId != null &&
        (mode == ComposeMode.reply || mode == ComposeMode.replyAll)) {
      return _client.mail.reply(mailboxId, originalId, body);
    }
    if (originalId != null && mode == ComposeMode.forward) {
      return _client.mail.forward(mailboxId, originalId, body);
    }
    return _client.mail.send(mailboxId, body);
  }

  Future<String> saveDraft(String mailboxId, DraftInput draft) async =>
      (await _client.mail.saveDraft(mailboxId, draft.toJson()))['id'] as String;

  Future<void> discard(String mailboxId, String draftId) =>
      _client.mail.delete(mailboxId, draftId);

  Future<void> sendDraft(String mailboxId, EmailMessage draft) async {
    final to = splitAddresses(draft.recipient);
    if (to.isEmpty) {
      throw const ApiFailure(
        code: ApiErrorCode.invalidRequest,
        message: 'This draft has no recipient. Open it and add one.',
      );
    }
    final details = await _mailboxes.details(mailboxId);
    await send(
      mailboxId,
      OutgoingEmail(
        to: to,
        cc: splitAddresses(draft.cc),
        bcc: splitAddresses(draft.bcc),
        from: details.from,
        subject: draft.subject.trim().isEmpty ? '(no subject)' : draft.subject,
        html: looksLikeHtml(draft.body) ? draft.body : textToHtml(draft.body),
        text: htmlToPlainText(draft.body),
      ),
      mode: draft.inReplyTo == null ? ComposeMode.compose : ComposeMode.reply,
      originalId: draft.inReplyTo,
    );
    await discard(mailboxId, draft.id);
  }
}

extension OutgoingEmailJson on OutgoingEmail {
  Json toJson() => {
    'to': to.length == 1 ? to.first : to,
    if (cc.isNotEmpty) 'cc': cc,
    if (bcc.isNotEmpty) 'bcc': bcc,
    'from': from,
    'subject': subject,
    'html': html,
    'text': text,
    if (attachments.isNotEmpty)
      'attachments': [
        for (final a in attachments)
          {
            'content': base64Encode(a.bytes),
            'filename': a.filename,
            'type': a.type,
            'disposition': 'attachment',
          },
      ],
  };
}

extension DraftInputJson on DraftInput {
  Json toJson() => {
    'to': to,
    'cc': cc,
    'bcc': bcc,
    'subject': subject,
    'body': body,
    'in_reply_to': ?inReplyTo,
    'thread_id': ?threadId,
    'draft_id': ?draftId,
  };
}
