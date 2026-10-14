import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/compose.dart';
import '../models/session_state.dart';
import '../models/thread.dart';
import '../notifier/session_notifier.dart';
import '../screens/agent/agent_screen.dart';
import '../screens/mail/compose_screen.dart';
import '../screens/mail/inbox_screen.dart';
import '../screens/mail/thread_screen.dart';
import '../screens/mailboxes/mailboxes_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/way_in/sign_in_screen.dart';
import 'home_shell.dart';
import 'splash_screen.dart';

abstract final class Routes {
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String mailboxes = '/mailboxes';
  static const String mail = '/mail';
  static const String search = '/search';
  static const String agent = '/agent';
  static const String settings = '/settings';
  static const String compose = '/compose';
  static const String threadPattern = '/thread/:id';

  static String thread(ThreadRef ref, {required String folder}) {
    final query = Uri(queryParameters: {'f': folder, 't': ?ref.threadId}).query;
    return '/thread/${Uri.encodeComponent(ref.emailId)}?$query';
  }
}

final rootNavigator = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefresh(ref);
  ref.onDispose(refresh.dispose);

  String mailboxOf() => switch (ref.read(sessionProvider).value) {
    SignedIn(:final mailboxId?) => mailboxId,
    _ => '',
  };

  return GoRouter(
    navigatorKey: rootNavigator,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final here = state.matchedLocation;
      if (session.isLoading && !session.hasValue) {
        return here == Routes.splash ? null : Routes.splash;
      }
      return switch (session.value) {
        SignedOut() ||
        Expired() ||
        null => here == Routes.signIn ? null : Routes.signIn,
        SignedIn(mailboxId: null) =>
          here == Routes.mailboxes ? null : Routes.mailboxes,
        SignedIn() =>
          here == Routes.splash || here == Routes.signIn ? Routes.mail : null,
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: Routes.mailboxes,
        builder: (_, _) => const MailboxesScreen(),
      ),
      GoRoute(
        path: Routes.compose,
        builder: (_, state) => ComposeScreen(
          mailboxId: mailboxOf(),
          args: state.extra is ComposeArgs
              ? state.extra! as ComposeArgs
              : const ComposeArgs(),
        ),
      ),
      GoRoute(
        path: Routes.threadPattern,
        builder: (_, state) => ThreadScreen(
          mailboxId: mailboxOf(),
          thread: ThreadRef(
            emailId: state.pathParameters['id']!,
            threadId: state.uri.queryParameters['t'],
          ),
          folder: state.uri.queryParameters['f'] ?? 'inbox',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.mail,
                builder: (_, _) => InboxScreen(
                  key: ValueKey(mailboxOf()),
                  mailboxId: mailboxOf(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                builder: (_, _) => SearchScreen(
                  key: ValueKey(mailboxOf()),
                  mailboxId: mailboxOf(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.agent,
                builder: (_, _) => AgentScreen(
                  key: ValueKey(mailboxOf()),
                  mailboxId: mailboxOf(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => SettingsScreen(mailboxId: mailboxOf()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Ref ref) {
    _subscription = ref.listen(sessionProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<AsyncValue<SessionState>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
