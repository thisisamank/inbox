import 'package:flutter/foundation.dart';

@immutable
class Mailbox {
  const Mailbox({required this.id, required this.email});

  final String id;
  final String email;
}

@immutable
class MailboxSummary {
  const MailboxSummary({required this.mailbox, required this.unread});

  final Mailbox mailbox;
  final int? unread;
}

@immutable
class MailboxDetails {
  const MailboxDetails({required this.email, required this.settings});

  final String email;
  final Map<String, dynamic> settings;

  String get fromName => (settings['fromName'] as String?)?.trim() ?? '';

  String get signature {
    final sig = settings['signature'];
    if (sig is! Map || sig['enabled'] != true) return '';
    return (sig['text'] as String?) ?? '';
  }

  String get agentSystemPrompt =>
      (settings['agentSystemPrompt'] as String?) ?? '';

  Object get from => fromName.isEmpty || fromName == email
      ? email
      : {'email': email, 'name': fromName};
}

@immutable
class Folder {
  const Folder({
    required this.id,
    required this.name,
    required this.unreadCount,
  });

  static const inbox = 'inbox';
  static const draft = 'draft';
  static const sent = 'sent';
  static const archive = 'archive';
  static const spam = 'spam';
  static const trash = 'trash';
  static const systemOrder = [inbox, draft, sent, archive, spam, trash];

  final String id;
  final String name;
  final int unreadCount;

  bool get isSystem => systemOrder.contains(id);
}

String folderLabel(String id, List<Folder> folders) {
  for (final f in folders) {
    if (f.id == id) return f.name;
  }
  return id.isEmpty ? id : id[0].toUpperCase() + id.substring(1);
}
