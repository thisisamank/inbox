import 'dart:async';

import 'package:api/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../models/session_state.dart';

part 'session_notifier.g.dart';

@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  Future<SessionState> build() async {
    final expiry = identity.expired.listen((_) => unawaited(expire()));
    ref.onDispose(expiry.cancel);
    final stored = await identity.storedSession();
    if (stored == null) return SignedOut(lastInbox: identity.lastInbox);
    return SignedIn(inbox: stored.baseUrl, mailboxId: identity.mailboxId);
  }

  void signedIn(AccessSession session) {
    state = AsyncData(
      SignedIn(inbox: session.baseUrl, mailboxId: identity.mailboxId),
    );
  }

  Future<void> chooseMailbox(String? mailboxId) async {
    await identity.chooseMailbox(mailboxId);
    final current = state.value;
    if (current is SignedIn) state = AsyncData(current.withMailbox(mailboxId));
  }

  Future<void> expire() async {
    final current = state.value;
    if (current is! SignedIn) return;
    await identity.forgetSession();
    state = AsyncData(Expired(current.inbox));
  }

  Future<void> signOut() async {
    await identity.forgetSession();
    state = AsyncData(SignedOut(lastInbox: identity.lastInbox));
  }
}
