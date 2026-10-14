import 'dart:async';

import 'package:api/api.dart';
import 'package:core/core.dart';

import 'browser.dart';

class SignInAttempt {
  SignInAttempt._(this._ticket, this.session);

  final AccessTransferTicket _ticket;
  final Future<AccessSession> session;

  void cancel() => _ticket.cancel();
}

class IdentityRepository {
  IdentityRepository(
    this._client,
    this._transfer,
    this._choices,
    this._browser,
  );

  final ApiClient _client;
  final AccessTransfer _transfer;
  final InboxChoiceStore _choices;
  final Browser _browser;
  final _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void reportExpired() => _expired.add(null);

  Uri? get lastInbox => _choices.lastInbox;

  String? get mailboxId => _choices.mailboxId;

  Future<AccessSession?> storedSession() => _client.currentSession();

  Future<SignInAttempt> beginSignIn(Uri inbox) async {
    final ticket = await mapApiFailure(() => _transfer.begin(inbox));
    final opened = await _browser.open(ticket.loginUrl);
    if (!opened) {
      throw const ApiFailure(
        code: ApiErrorCode.unknown,
        message: 'Could not open the browser.',
      );
    }
    final session = ticket
        .session()
        .then((session) async {
          await _client.saveSession(session);
          await _choices.rememberInbox(session.baseUrl);
          return session;
        })
        .whenComplete(_browser.close);
    return SignInAttempt._(ticket, session);
  }

  Future<void> chooseMailbox(String? id) => _choices.chooseMailbox(id);

  Future<void> forgetSession() => _client.clearSession();
}
