import 'package:flutter/foundation.dart';

sealed class SessionState {
  const SessionState();
}

class SignedOut extends SessionState {
  const SignedOut({this.lastInbox});

  final Uri? lastInbox;
}

class Expired extends SessionState {
  const Expired(this.inbox);

  final Uri inbox;
}

@immutable
class SignedIn extends SessionState {
  const SignedIn({required this.inbox, this.mailboxId});

  final Uri inbox;
  final String? mailboxId;

  SignedIn withMailbox(String? id) => SignedIn(inbox: inbox, mailboxId: id);
}
