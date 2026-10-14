import 'dart:convert';
import 'dart:typed_data';

import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final List<RequestOptions> seen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  final session = AccessSession(
    baseUrl: Uri.parse('https://inbox.example.dev'),
    token: 'jwt',
  );

  ({ApiClient client, FakeAdapter adapter, List<String> events}) build(
    ResponseBody Function(RequestOptions) respond,
  ) {
    final adapter = FakeAdapter(respond);
    final events = <String>[];
    final client = ApiClient(
      sessionStore: InMemorySessionStore(session),
      dio: Dio()..httpClientAdapter = adapter,
      onSessionExpired: () => events.add('expired'),
      onFailure: (failure, endpoint) =>
          events.add('${failure.code.wireName} $endpoint'),
    );
    return (client: client, adapter: adapter, events: events);
  }

  test('requests go to the stored inbox with the Access cookie', () async {
    final t = build(
      (o) => o.path.endsWith('/emails')
          ? json({'emails': [], 'totalCount': 0})
          : json([
              {'id': 'a@x.dev'},
            ]),
    );
    await t.client.mailboxes.list();
    await t.client.mail.threads('a@x.dev', folder: 'inbox', page: 2);
    final first = t.adapter.seen.first;
    expect(first.uri.toString(), 'https://inbox.example.dev/api/v1/mailboxes');
    expect(first.headers['Cookie'], 'CF_Authorization=jwt');
    final second = t.adapter.seen.last.uri;
    expect(second.path, '/api/v1/mailboxes/a%40x.dev/emails');
    expect(second.queryParameters, {
      'folder': 'inbox',
      'threaded': 'true',
      'page': '2',
      'limit': '25',
    });
  });

  test('agent history keeps the mailbox id raw', () async {
    final t = build((_) => json([]));
    await t.client.agent.messages('a@x.dev');
    expect(
      t.adapter.seen.single.uri.path,
      '/agents/email-agent/a@x.dev/get-messages',
    );
  });

  test('a redirect to Access reports an expired session', () async {
    final t = build(
      (_) => ResponseBody.fromString(
        '',
        302,
        headers: {
          'location': [
            'https://team.cloudflareaccess.com/cdn-cgi/access/login/x',
          ],
        },
      ),
    );
    await expectLater(
      t.client.mailboxes.list(),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.isUnauthorized,
          'unauthorized',
          isTrue,
        ),
      ),
    );
    expect(t.events, ['expired', 'unauthorized /api/v1/mailboxes']);
  });

  test('server errors carry the error message and status', () async {
    final t = build((_) => json({'error': 'Mailbox already exists'}, 409));
    await expectLater(
      t.client.mailboxes.create(email: 'a@x.dev', name: 'A'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.code, 'code', ApiErrorCode.conflict)
            .having((f) => f.message, 'message', 'Mailbox already exists'),
      ),
    );
    expect(t.events, ['conflict /api/v1/mailboxes']);
  });

  test('without a session nothing is sent', () async {
    final adapter = FakeAdapter((_) => json({}));
    final client = ApiClient(
      sessionStore: InMemorySessionStore(),
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(client.config(), throwsA(isA<ApiFailure>()));
    expect(adapter.seen, isEmpty);
  });

  test('endpointOf hides ids so one route counts once', () {
    expect(
      ApiClient.endpointOf('/api/v1/mailboxes/a%40x.dev/emails/123/move'),
      '/api/v1/mailboxes/*/emails/*/move',
    );
    expect(ApiClient.endpointOf('/api/v1/config'), '/api/v1/config');
  });
}
