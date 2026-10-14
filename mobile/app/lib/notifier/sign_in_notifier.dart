import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../repositories/identity_repository.dart';
import 'session_notifier.dart';

part 'sign_in_notifier.g.dart';

@riverpod
class SignIn extends _$SignIn {
  SignInAttempt? _attempt;

  @override
  FutureOr<void> build() {
    ref.onDispose(() => _attempt?.cancel());
  }

  Future<void> start(Uri inbox) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final attempt = await identity.beginSignIn(inbox);
      _attempt = attempt;
      final session = await attempt.session;
      ref.read(sessionProvider.notifier).signedIn(session);
    });
    _attempt = null;
    if (ref.mounted) state = result;
  }

  void cancel() => _attempt?.cancel();
}
