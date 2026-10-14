import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../models/mailbox.dart';

part 'mailboxes_notifier.g.dart';

@riverpod
class Mailboxes extends _$Mailboxes {
  @override
  Future<List<MailboxSummary>> build() => mailboxes.summaries();

  Future<Mailbox> create({required String email, required String name}) async {
    final created = await mailboxes.create(email: email, name: name);
    ref.invalidateSelf();
    return created;
  }
}

@riverpod
class MailboxCreation extends _$MailboxCreation {
  @override
  FutureOr<Mailbox?> build() => null;

  Future<Mailbox?> create({required String email, required String name}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () =>
          ref.read(mailboxesProvider.notifier).create(email: email, name: name),
    );
    if (ref.mounted) state = result;
    return result.value;
  }
}

@riverpod
Future<List<String>> domains(Ref ref) => mailboxes.domains();

@riverpod
Future<MailboxDetails> mailboxDetails(Ref ref, String mailboxId) =>
    mailboxes.details(mailboxId);
