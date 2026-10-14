import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'access_session.dart';
import 'api_failure.dart';
import 'json.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({
    required SessionStore sessionStore,
    Dio? dio,
    this.onSessionExpired,
    this.onFailure,
  }) : _store = sessionStore,
       _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: false,
      contentType: Headers.jsonContentType,
    );
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _attachSession, onError: _reportError),
    );
    mailboxes = MailboxesEndpoints._(this);
    mail = MailEndpoints._(this);
    agent = AgentEndpoints._(this);
  }

  final Dio _dio;
  final SessionStore _store;
  final void Function()? onSessionExpired;
  final void Function(ApiFailure failure, String endpoint)? onFailure;

  late final MailboxesEndpoints mailboxes;
  late final MailEndpoints mail;
  late final AgentEndpoints agent;

  Future<AccessSession?> currentSession() => _store.read();

  Future<void> saveSession(AccessSession session) => _store.write(session);

  Future<void> clearSession() => _store.clear();

  Future<AccessSession> requireSession() async {
    final session = await _store.read();
    if (session == null) throw ApiFailure.missingSession;
    return session;
  }

  Future<Json> config() async => await _get('/api/v1/config') as Json;

  Future<void> _attachSession(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final session = await _store.read();
    if (session == null) {
      handler.reject(
        DioException(requestOptions: options, error: ApiFailure.missingSession),
      );
      return;
    }
    options
      ..baseUrl = session.baseUrl.toString()
      ..headers.addAll(session.headers);
    handler.next(options);
  }

  void _reportError(DioException error, ErrorInterceptorHandler handler) {
    final failure = ApiFailure.fromDioException(error);
    if (failure.isUnauthorized && error.error is! ApiFailure) {
      onSessionExpired?.call();
    }
    onFailure?.call(failure, endpointOf(error.requestOptions.path));
    handler.reject(error);
  }

  static String endpointOf(String path) => path
      .split('/')
      .map(
        (segment) =>
            segment.isEmpty || _plain.hasMatch(segment) ? segment : '*',
      )
      .join('/');

  static final RegExp _plain = RegExp(r'^(v1|[a-z]+(-[a-z]+)*)$');

  Future<Object?> _get(String path, {Map<String, Object?>? query}) =>
      mapApiFailure(() async {
        final res = await _dio.get<Object?>(path, queryParameters: query);
        return res.data;
      });

  Future<Object?> _send(String method, String path, [Object? body]) =>
      mapApiFailure(() async {
        final res = await _dio.request<Object?>(
          path,
          data: body,
          options: Options(method: method),
        );
        return res.data;
      });

  Future<Uint8List> _bytes(String path) => mapApiFailure(() async {
    final res = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  });
}

String mailboxPath(String mailboxId) =>
    '/api/v1/mailboxes/${Uri.encodeComponent(mailboxId)}';

String _id(String value) => Uri.encodeComponent(value);

String attachmentPathFor(
  String mailboxId,
  String emailId,
  String attachmentId,
) =>
    '${mailboxPath(mailboxId)}/emails/${_id(emailId)}/attachments/${_id(attachmentId)}';

class MailboxesEndpoints {
  MailboxesEndpoints._(this._client);

  final ApiClient _client;

  Future<List<Object?>> list() async =>
      await _client._get('/api/v1/mailboxes') as List<Object?>;

  Future<Json> create({required String email, required String name}) async =>
      await _client._send('POST', '/api/v1/mailboxes', {
            'email': email,
            'name': name,
          })
          as Json;

  Future<Json> get(String mailboxId) async =>
      await _client._get(mailboxPath(mailboxId)) as Json;

  Future<Json> updateSettings(String mailboxId, Json settings) async =>
      await _client._send('PUT', mailboxPath(mailboxId), {'settings': settings})
          as Json;

  Future<List<Object?>> folders(String mailboxId) async =>
      await _client._get('${mailboxPath(mailboxId)}/folders') as List<Object?>;

  Future<Json> createFolder(String mailboxId, String name) async =>
      await _client._send('POST', '${mailboxPath(mailboxId)}/folders', {
            'name': name,
          })
          as Json;
}

class MailEndpoints {
  MailEndpoints._(this._client);

  final ApiClient _client;

  Future<Json> threads(
    String mailboxId, {
    required String folder,
    int page = 1,
    int limit = 25,
  }) async =>
      await _client._get(
            '${mailboxPath(mailboxId)}/emails',
            query: {
              'folder': folder,
              'threaded': 'true',
              'page': '$page',
              'limit': '$limit',
            },
          )
          as Json;

  Future<Json> search(
    String mailboxId,
    Map<String, String> filters, {
    int page = 1,
    int limit = 25,
  }) async =>
      await _client._get(
            '${mailboxPath(mailboxId)}/search',
            query: {...filters, 'page': '$page', 'limit': '$limit'},
          )
          as Json;

  Future<List<Object?>> thread(String mailboxId, String threadId) async =>
      await _client._get('${mailboxPath(mailboxId)}/threads/${_id(threadId)}')
          as List<Object?>;

  Future<Json> email(String mailboxId, String emailId) async =>
      await _client._get('${mailboxPath(mailboxId)}/emails/${_id(emailId)}')
          as Json;

  Future<void> markThreadRead(String mailboxId, String threadId) => _client
      ._send('POST', '${mailboxPath(mailboxId)}/threads/${_id(threadId)}/read');

  Future<void> setRead(
    String mailboxId,
    String emailId, {
    required bool read,
  }) => _client._send(
    'PUT',
    '${mailboxPath(mailboxId)}/emails/${_id(emailId)}',
    {'read': read},
  );

  Future<void> move(String mailboxId, String emailId, String folderId) =>
      _client._send(
        'POST',
        '${mailboxPath(mailboxId)}/emails/${_id(emailId)}/move',
        {'folderId': folderId},
      );

  Future<void> delete(String mailboxId, String emailId) => _client._send(
    'DELETE',
    '${mailboxPath(mailboxId)}/emails/${_id(emailId)}',
  );

  Future<void> send(String mailboxId, Json email) =>
      _client._send('POST', '${mailboxPath(mailboxId)}/emails', email);

  Future<void> reply(String mailboxId, String originalId, Json email) =>
      _client._send(
        'POST',
        '${mailboxPath(mailboxId)}/emails/${_id(originalId)}/reply',
        email,
      );

  Future<void> forward(String mailboxId, String originalId, Json email) =>
      _client._send(
        'POST',
        '${mailboxPath(mailboxId)}/emails/${_id(originalId)}/forward',
        email,
      );

  Future<Json> saveDraft(String mailboxId, Json draft) async =>
      await _client._send('POST', '${mailboxPath(mailboxId)}/drafts', draft)
          as Json;

  String attachmentPath(
    String mailboxId,
    String emailId,
    String attachmentId,
  ) => attachmentPathFor(mailboxId, emailId, attachmentId);

  Future<Uint8List> attachment(
    String mailboxId,
    String emailId,
    String attachmentId,
  ) => _client._bytes(attachmentPath(mailboxId, emailId, attachmentId));
}

class AgentEndpoints {
  AgentEndpoints._(this._client);

  final ApiClient _client;

  Future<List<Object?>> messages(String mailboxId) async =>
      await _client._get('/agents/email-agent/$mailboxId/get-messages')
          as List<Object?>;
}

Future<T> mapApiFailure<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (error) {
    throw ApiFailure.fromDioException(error);
  }
}
