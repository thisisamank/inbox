import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agentic_inbox/di/service_locator.dart';
import 'package:agentic_inbox/models/compose.dart';
import 'package:agentic_inbox/repositories/browser.dart';
import 'package:agentic_inbox/repositories/files.dart';
import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Handler = Object? Function(RequestOptions request);

class FakeServer implements HttpClientAdapter {
  final Map<String, Handler> routes = {};
  final List<String> calls = [];
  final List<RequestOptions> requests = [];
  int status = 200;
  Map<String, List<String>> headers = const {};

  void on(String method, String path, Handler handler) =>
      routes['$method $path'] = handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.uri.path}';
    calls.add(key);
    requests.add(options);
    final handler = routes[key];
    if (status != 200) {
      return ResponseBody.fromString('', status, headers: headers);
    }
    if (handler == null) {
      return ResponseBody.fromString(
        '{"error":"no route $key"}',
        404,
        headers: _json,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(handler(options)),
      200,
      headers: _json,
    );
  }

  static final _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

class FakeBrowser implements Browser {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri url, {bool inApp = true}) async {
    opened.add(url);
    return true;
  }

  @override
  Future<void> close() async {}
}

class FakeFiles implements Files {
  List<OutgoingAttachment> picked = const [];
  final List<String> shared = [];

  @override
  Future<List<OutgoingAttachment>> pick() async => picked;

  @override
  Future<void> share({
    required String folder,
    required String filename,
    required String mimetype,
    required Uint8List bytes,
  }) async => shared.add(filename);
}

class FakeChannel implements AgentChannel {
  final _events = StreamController<Json>.broadcast();
  final List<Json> sent = [];
  final _ready = Completer<void>();
  bool closed = false;

  void connect() => _ready.complete();

  void emit(Json event) => _events.add(event);

  @override
  Future<void> get ready => _ready.future;

  @override
  Stream<Json> get events => _events.stream;

  @override
  void send(Json message) => sent.add(message);

  @override
  void close() => closed = true;
}

final inbox = Uri.parse('https://inbox.example.dev');
const mailboxId = 'me@akxr.in';
final mailboxPathPrefix = '/api/v1/mailboxes/${Uri.encodeComponent(mailboxId)}';

class Fakes {
  Fakes({
    required this.server,
    required this.browser,
    required this.files,
    required this.channel,
    required this.choices,
  });

  final FakeServer server;
  final FakeBrowser browser;
  final FakeFiles files;
  final FakeChannel channel;
  final InMemoryInboxChoiceStore choices;
}

Future<Fakes> registerFakes({
  bool signedIn = true,
  String? mailbox = mailboxId,
}) async {
  await getIt.reset();
  final fakes = Fakes(
    server: FakeServer(),
    browser: FakeBrowser(),
    files: FakeFiles(),
    channel: FakeChannel(),
    choices: InMemoryInboxChoiceStore(lastInbox: inbox, mailboxId: mailbox),
  );
  await setUp(
    sessionStore: InMemorySessionStore(
      signedIn ? AccessSession(baseUrl: inbox, token: 'jwt') : null,
    ),
    choiceStore: fakes.choices,
    browser: fakes.browser,
    files: fakes.files,
    channels: (_, _) => fakes.channel,
    dio: Dio()..httpClientAdapter = fakes.server,
  );
  return fakes;
}

Future<void> tearDownFakes() => getIt.reset();

Widget wrap(Widget child) => ProviderScope(
  child: MaterialApp(theme: InTheme.build(Brightness.light), home: child),
);

Json threadJson({
  required String id,
  String? threadId,
  String subject = 'Hello',
  String sender = 'priya@vendor.com',
  bool read = false,
  int count = 1,
  int? unread,
  bool hasDraft = false,
  String folder = 'inbox',
}) => {
  'id': id,
  'thread_id': threadId,
  'subject': subject,
  'sender': sender,
  'date': '2026-10-13T16:52:00.000Z',
  'read': read,
  'snippet': '<p>Hi Aman</p>',
  'thread_count': count,
  'thread_unread_count': unread ?? (read ? 0 : 1),
  'participants': sender,
  'has_draft': hasDraft,
  'folder_id': folder,
};

Json emailJson({
  required String id,
  String? threadId,
  String folder = 'inbox',
  String body = '<p>Hi Aman</p>',
  String recipient = mailboxId,
  String? inReplyTo,
  bool read = false,
}) => {
  'id': id,
  'thread_id': threadId,
  'folder_id': folder,
  'subject': 'Q4 contract',
  'sender': 'priya@vendor.com',
  'recipient': recipient,
  'date': '2026-10-13T16:52:00.000Z',
  'read': read,
  'body': body,
  'in_reply_to': inReplyTo,
  'raw_headers': '[{"key":"from","value":"Priya Raman <priya@vendor.com>"}]',
  'attachments': <Object>[],
};
