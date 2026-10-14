import 'dart:convert';

import 'package:api/api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const FlutterSecureStorage inboxSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? inboxSecureStorage;

  static const String _sessionKey = 'inbox.session';

  final FlutterSecureStorage _storage;

  AccessSession? _held;
  bool _loaded = false;

  @override
  Future<AccessSession?> read() async {
    if (_loaded) return _held;
    _held = await _fromStorage();
    _loaded = true;
    return _held;
  }

  Future<AccessSession?> _fromStorage() async {
    try {
      final held = await _storage.read(key: _sessionKey);
      if (held == null) return null;
      final json = jsonDecode(held) as Map<String, Object?>;
      final url = json['baseUrl'] as String?;
      final token = json['token'] as String?;
      if (url == null || token == null) return null;
      return AccessSession(baseUrl: Uri.parse(url), token: token);
    } catch (error) {
      debugPrint('SecureSessionStore: could not be read ($error)');
      return null;
    }
  }

  @override
  Future<void> write(AccessSession session) async {
    _held = session;
    _loaded = true;
    try {
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode({
          'baseUrl': session.baseUrl.toString(),
          'token': session.token,
        }),
      );
    } catch (error) {
      debugPrint('SecureSessionStore: could not be written ($error)');
    }
  }

  @override
  Future<void> clear() async {
    _held = null;
    _loaded = true;
    try {
      await _storage.delete(key: _sessionKey);
    } catch (error) {
      debugPrint('SecureSessionStore: could not be cleared ($error)');
    }
  }
}
