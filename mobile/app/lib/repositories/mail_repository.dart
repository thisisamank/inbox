import 'dart:convert';
import 'dart:typed_data';

import 'package:api/api.dart';

import '../models/email.dart';
import '../models/thread.dart';
import 'files.dart';

class MailRepository {
  MailRepository(this._client, this._files);

  final ApiClient _client;
  final Files _files;

  Future<ThreadPage> threads(
    String mailboxId, {
    required String folder,
    int page = 1,
    int limit = 25,
  }) async => (await _client.mail.threads(
    mailboxId,
    folder: folder,
    page: page,
    limit: limit,
  )).toPage();

  Future<ThreadPage> search(
    String mailboxId,
    Map<String, String> filters, {
    int page = 1,
    int limit = 25,
  }) async => (await _client.mail.search(
    mailboxId,
    filters,
    page: page,
    limit: limit,
  )).toPage();

  Future<List<EmailMessage>> conversation(
    String mailboxId,
    ThreadRef ref,
  ) async {
    final threadId = ref.threadId;
    if (threadId != null) {
      final list = await _client.mail.thread(mailboxId, threadId);
      if (list.isNotEmpty) {
        return [for (final e in list) (e! as Json).toEmail()];
      }
    }
    return [await email(mailboxId, ref.emailId)];
  }

  Future<EmailMessage> email(String mailboxId, String emailId) async =>
      (await _client.mail.email(mailboxId, emailId)).toEmail();

  Future<List<String>> idsIn(
    String mailboxId,
    ThreadRef ref,
    String folder,
  ) async {
    final threadId = ref.threadId;
    if (threadId == null) return [ref.emailId];
    final ids = [
      for (final e in (await _client.mail.thread(
        mailboxId,
        threadId,
      )).cast<Json>())
        if (e['folder_id'] == folder) e['id'] as String,
    ];
    return ids.isEmpty ? [ref.emailId] : ids;
  }

  Future<List<String>> move(
    String mailboxId,
    ThreadRef ref, {
    required String from,
    required String to,
  }) async {
    final ids = await idsIn(mailboxId, ref, from);
    await moveIds(mailboxId, ids, to);
    return ids;
  }

  Future<void> moveIds(String mailboxId, List<String> ids, String to) =>
      Future.wait(ids.map((id) => _client.mail.move(mailboxId, id, to)));

  Future<void> deleteForever(
    String mailboxId,
    ThreadRef ref, {
    required String from,
  }) async {
    final ids = await idsIn(mailboxId, ref, from);
    await Future.wait(ids.map((id) => _client.mail.delete(mailboxId, id)));
  }

  Future<void> delete(String mailboxId, String emailId) =>
      _client.mail.delete(mailboxId, emailId);

  Future<void> setRead(
    String mailboxId,
    ThreadRef ref, {
    required bool read,
  }) async {
    final threadId = ref.threadId;
    if (read && threadId != null) {
      await _client.mail.markThreadRead(mailboxId, threadId);
    } else {
      await _client.mail.setRead(mailboxId, ref.emailId, read: read);
    }
  }

  Future<void> markRead(
    String mailboxId,
    ThreadRef ref,
    List<EmailMessage> messages,
  ) async {
    final unread = messages.where((m) => !m.read && !m.isDraft).toList();
    if (unread.isEmpty) return;
    final threadId = ref.threadId;
    if (threadId != null) {
      await _client.mail.markThreadRead(mailboxId, threadId);
    } else {
      await Future.wait(
        unread.map((m) => _client.mail.setRead(mailboxId, m.id, read: true)),
      );
    }
  }

  Future<AccessSession> access() => _client.requireSession();

  Future<void> shareAttachment(
    String mailboxId,
    String emailId,
    Attachment attachment,
  ) async {
    final Uint8List bytes = await _client.mail.attachment(
      mailboxId,
      emailId,
      attachment.id,
    );
    await _files.share(
      folder: emailId,
      filename: attachment.filename,
      mimetype: attachment.mimetype,
      bytes: bytes,
    );
  }
}

extension on Json {
  ThreadPage toPage() => ThreadPage(
    threads: [
      for (final e in this['emails'] as List? ?? const [])
        (e as Json).toThread(),
    ],
    total: (this['totalCount'] as num?)?.toInt() ?? 0,
  );

  ThreadSummary toThread() => ThreadSummary(
    id: this['id'] as String,
    threadId: this['thread_id'] as String?,
    subject: (this['subject'] as String?) ?? '',
    sender: (this['sender'] as String?) ?? '',
    date: DateTime.tryParse((this['date'] as String?) ?? '')?.toLocal(),
    read: this['read'] == true,
    snippet: (this['snippet'] as String?) ?? '',
    count: (this['thread_count'] as num?)?.toInt() ?? 1,
    unreadCount: (this['thread_unread_count'] as num?)?.toInt(),
    participants:
        (this['participants'] as String?) ?? (this['sender'] as String?) ?? '',
    hasDraft: this['has_draft'] == true,
    folderId: this['folder_id'] as String?,
    folderName: this['folder_name'] as String?,
  );

  EmailMessage toEmail() => EmailMessage(
    id: this['id'] as String,
    threadId: this['thread_id'] as String?,
    folderId: this['folder_id'] as String?,
    subject: (this['subject'] as String?) ?? '',
    sender: (this['sender'] as String?) ?? '',
    fromHeader: _header(this['raw_headers'], 'from'),
    recipient: (this['recipient'] as String?) ?? '',
    cc: this['cc'] as String?,
    bcc: this['bcc'] as String?,
    date: DateTime.tryParse((this['date'] as String?) ?? '')?.toLocal(),
    read: this['read'] == true,
    body: (this['body'] as String?) ?? '',
    inReplyTo: this['in_reply_to'] as String?,
    attachments: [
      for (final a in this['attachments'] as List? ?? const [])
        Attachment(
          id: (a as Json)['id'] as String,
          filename: (a['filename'] as String?) ?? 'attachment',
          mimetype: (a['mimetype'] as String?) ?? 'application/octet-stream',
          size: (a['size'] as num?)?.toInt() ?? 0,
          contentId: a['content_id'] as String?,
          disposition: a['disposition'] as String?,
        ),
    ],
  );
}

String? _header(Object? raw, String key) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    for (final h in jsonDecode(raw) as List) {
      if (h is Map && (h['key'] as String?)?.toLowerCase() == key) {
        return h['value'] as String?;
      }
    }
  } on FormatException {
    return null;
  }
  return null;
}
