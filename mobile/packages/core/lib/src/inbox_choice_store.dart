import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_session_store.dart';

abstract interface class InboxChoiceStore {
  Uri? get lastInbox;
  String? get mailboxId;
  Future<void> load();
  Future<void> rememberInbox(Uri baseUrl);
  Future<void> chooseMailbox(String? mailboxId);
}

class InMemoryInboxChoiceStore implements InboxChoiceStore {
  InMemoryInboxChoiceStore({this.lastInbox, this.mailboxId});

  @override
  Uri? lastInbox;

  @override
  String? mailboxId;

  @override
  Future<void> load() async {}

  @override
  Future<void> rememberInbox(Uri baseUrl) async => lastInbox = baseUrl;

  @override
  Future<void> chooseMailbox(String? mailboxId) async =>
      this.mailboxId = mailboxId;
}

class SecureInboxChoiceStore implements InboxChoiceStore {
  SecureInboxChoiceStore({FlutterSecureStorage? storage})
    : _storage = storage ?? inboxSecureStorage;

  static const String _inboxKey = 'inbox.last_inbox';
  static const String _mailboxKey = 'inbox.mailbox';

  final FlutterSecureStorage _storage;

  @override
  Uri? lastInbox;

  @override
  String? mailboxId;

  @override
  Future<void> load() async {
    try {
      final inbox = await _storage.read(key: _inboxKey);
      lastInbox = inbox == null ? null : Uri.parse(inbox);
      mailboxId = await _storage.read(key: _mailboxKey);
    } catch (error) {
      debugPrint('SecureInboxChoiceStore: could not be read ($error)');
    }
  }

  @override
  Future<void> rememberInbox(Uri baseUrl) async {
    if (lastInbox != baseUrl) await chooseMailbox(null);
    lastInbox = baseUrl;
    await _write(_inboxKey, baseUrl.toString());
  }

  @override
  Future<void> chooseMailbox(String? mailboxId) async {
    this.mailboxId = mailboxId;
    await _write(_mailboxKey, mailboxId);
  }

  Future<void> _write(String key, String? value) async {
    try {
      if (value == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (error) {
      debugPrint('SecureInboxChoiceStore: could not be written ($error)');
    }
  }
}
