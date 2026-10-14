import 'package:api/api.dart';

import '../models/mailbox.dart';

class MailboxRepository {
  MailboxRepository(this._client);

  final ApiClient _client;

  Future<List<MailboxSummary>> summaries() async {
    final list = await _client.mailboxes.list();
    final mailboxes = [for (final m in list) (m! as Json).toMailbox()]
      ..sort((a, b) => a.email.compareTo(b.email));
    return Future.wait(
      mailboxes.map((m) async {
        try {
          final inbox = (await folders(
            m.id,
          )).where((f) => f.id == Folder.inbox);
          return MailboxSummary(
            mailbox: m,
            unread: inbox.isEmpty ? 0 : inbox.first.unreadCount,
          );
        } on ApiFailure catch (failure) {
          if (failure.isUnauthorized) rethrow;
          return MailboxSummary(mailbox: m, unread: null);
        }
      }),
    );
  }

  Future<Mailbox> create({required String email, required String name}) async =>
      (await _client.mailboxes.create(email: email, name: name)).toMailbox();

  Future<List<String>> domains() async {
    final config = await _client.config();
    return [
      for (final d in config['domains'] as List? ?? const []) d as String,
    ];
  }

  Future<MailboxDetails> details(String mailboxId) async =>
      (await _client.mailboxes.get(mailboxId)).toDetails();

  Future<MailboxDetails> updateSettings(
    String mailboxId,
    Map<String, dynamic> settings,
  ) async =>
      (await _client.mailboxes.updateSettings(mailboxId, settings)).toDetails();

  Future<List<Folder>> folders(String mailboxId) async => [
    for (final f in await _client.mailboxes.folders(mailboxId))
      (f! as Json).toFolder(),
  ];

  Future<Folder> createFolder(String mailboxId, String name) async =>
      (await _client.mailboxes.createFolder(mailboxId, name)).toFolder();
}

extension on Json {
  Mailbox toMailbox() => Mailbox(
    id: this['id'] as String,
    email: (this['email'] ?? this['id']) as String,
  );

  MailboxDetails toDetails() => MailboxDetails(
    email: (this['email'] ?? this['id']) as String,
    settings: Map<String, dynamic>.from(this['settings'] as Map? ?? const {}),
  );

  Folder toFolder() => Folder(
    id: this['id'] as String,
    name: (this['name'] as String?) ?? this['id'] as String,
    unreadCount: (this['unreadCount'] as num?)?.toInt() ?? 0,
  );
}
