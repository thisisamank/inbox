import 'access_session.dart';

abstract interface class SessionStore {
  Future<AccessSession?> read();
  Future<void> write(AccessSession session);
  Future<void> clear();
}

class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this._session]);

  AccessSession? _session;

  @override
  Future<AccessSession?> read() async => _session;

  @override
  Future<void> write(AccessSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
