import 'package:flutter/foundation.dart';

@immutable
class Attachment {
  const Attachment({
    required this.id,
    required this.filename,
    required this.mimetype,
    required this.size,
    required this.contentId,
    required this.disposition,
  });

  final String id;
  final String filename;
  final String mimetype;
  final int size;
  final String? contentId;
  final String? disposition;

  bool get isInline => disposition == 'inline' && contentId != null;
}

@immutable
class EmailMessage {
  const EmailMessage({
    required this.id,
    required this.threadId,
    required this.folderId,
    required this.subject,
    required this.sender,
    required this.fromHeader,
    required this.recipient,
    required this.cc,
    required this.bcc,
    required this.date,
    required this.read,
    required this.body,
    required this.inReplyTo,
    required this.attachments,
  });

  final String id;
  final String? threadId;
  final String? folderId;
  final String subject;
  final String sender;
  final String? fromHeader;
  final String recipient;
  final String? cc;
  final String? bcc;
  final DateTime? date;
  final bool read;
  final String body;
  final String? inReplyTo;
  final List<Attachment> attachments;

  bool get isDraft => folderId == 'draft';

  String get senderName {
    final match = RegExp(r'^\s*"?([^"<]+?)"?\s*<').firstMatch(fromHeader ?? '');
    final name = match?[1]?.trim();
    if (name != null && name.isNotEmpty) return name;
    return sender.split('@').first;
  }
}
