import 'package:flutter/foundation.dart';

import 'email.dart';

enum ComposeMode { compose, reply, replyAll, forward }

@immutable
class ComposeArgs {
  const ComposeArgs({
    this.mode = ComposeMode.compose,
    this.original,
    this.draft,
  });

  final ComposeMode mode;
  final EmailMessage? original;
  final EmailMessage? draft;

  ComposeMode get effectiveMode {
    final d = draft;
    if (d != null) {
      return d.inReplyTo != null ? ComposeMode.reply : ComposeMode.compose;
    }
    return mode;
  }
}

@immutable
class ComposeFields {
  const ComposeFields({
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.body,
  });

  final String to;
  final String cc;
  final String bcc;
  final String subject;
  final String body;
}

@immutable
class OutgoingAttachment {
  const OutgoingAttachment({
    required this.filename,
    required this.type,
    required this.bytes,
  });

  final String filename;
  final String type;
  final List<int> bytes;
}

@immutable
class OutgoingEmail {
  const OutgoingEmail({
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    required this.from,
    required this.subject,
    required this.html,
    required this.text,
    this.attachments = const [],
  });

  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final Object from;
  final String subject;
  final String html;
  final String text;
  final List<OutgoingAttachment> attachments;
}

@immutable
class DraftInput {
  const DraftInput({
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.body,
    this.inReplyTo,
    this.threadId,
    this.draftId,
  });

  final String to;
  final String cc;
  final String bcc;
  final String subject;
  final String body;
  final String? inReplyTo;
  final String? threadId;
  final String? draftId;
}
