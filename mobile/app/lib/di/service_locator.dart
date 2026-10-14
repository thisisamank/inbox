import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../repositories/agent_repository.dart';
import '../repositories/browser.dart';
import '../repositories/compose_repository.dart';
import '../repositories/files.dart';
import '../repositories/identity_repository.dart';
import '../repositories/mail_repository.dart';
import '../repositories/mailbox_repository.dart';

final getIt = GetIt.instance;

Future<void> setUp({
  SessionStore? sessionStore,
  InboxChoiceStore? choiceStore,
  AccessTransfer? accessTransfer,
  Browser? browser,
  Files? files,
  ChannelFactory? channels,
  Dio? dio,
}) async {
  final store = sessionStore ?? SecureSessionStore();
  final choices = choiceStore ?? SecureInboxChoiceStore();
  await choices.load();

  late final IdentityRepository identityRepository;
  final client = ApiClient(
    sessionStore: store,
    dio: dio,
    onSessionExpired: () => identityRepository.reportExpired(),
  );
  identityRepository = IdentityRepository(
    client,
    accessTransfer ?? AccessTransfer(),
    choices,
    browser ?? const SystemBrowser(),
  );
  final mailboxRepository = MailboxRepository(client);

  getIt
    ..registerSingleton<SessionStore>(store)
    ..registerSingleton<InboxChoiceStore>(choices)
    ..registerSingleton<ApiClient>(client)
    ..registerSingleton<IdentityRepository>(identityRepository)
    ..registerSingleton<MailboxRepository>(mailboxRepository)
    ..registerSingleton<MailRepository>(
      MailRepository(client, files ?? const DeviceFiles()),
    )
    ..registerSingleton<ComposeRepository>(
      ComposeRepository(client, mailboxRepository),
    )
    ..registerSingleton<AgentRepository>(
      AgentRepository(client, channels: channels),
    )
    ..registerSingleton<Files>(files ?? const DeviceFiles())
    ..registerSingleton<Browser>(browser ?? const SystemBrowser());
}

Future<void> tearDown() => getIt.reset();

IdentityRepository get identity => getIt<IdentityRepository>();

MailboxRepository get mailboxes => getIt<MailboxRepository>();

MailRepository get mail => getIt<MailRepository>();

ComposeRepository get compose => getIt<ComposeRepository>();

AgentRepository get agent => getIt<AgentRepository>();

Files get files => getIt<Files>();

Browser get browser => getIt<Browser>();
