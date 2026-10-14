import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session_state.dart';
import '../../notifier/session_notifier.dart';
import '../../notifier/sign_in_notifier.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final _url = TextEditingController(
    text: switch (ref.read(sessionProvider).value) {
      SignedOut(:final lastInbox?) => lastInbox.host,
      _ => '',
    },
  );
  String? _invalid;

  void _start(Uri? inbox) {
    if (inbox == null) {
      setState(
        () => _invalid =
            'Enter the address of your inbox, for example inbox.example.workers.dev',
      );
      return;
    }
    setState(() => _invalid = null);
    ref.read(signInProvider.notifier).start(inbox);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final signIn = ref.watch(signInProvider);
    final expiredInbox = switch (ref.watch(sessionProvider).value) {
      Expired(:final inbox) => inbox,
      _ => null,
    };
    final expired = expiredInbox != null;
    final waiting = signIn.isLoading;
    final error = _invalid ?? (signIn.hasError ? '${signIn.error}' : null);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: InSpace.s10,
              vertical: InSpace.s9,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: expired
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: expired ? c.surface2 : c.accent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      expired ? Icons.lock_outline : Icons.mail_outline,
                      size: 32,
                      color: expired ? c.ink2 : c.onAccent,
                    ),
                  ),
                  const SizedBox(height: InSpace.s9),
                  Text(
                    expired ? 'Your Access session ended' : 'Agentic Inbox',
                    textAlign: expired ? TextAlign.center : TextAlign.start,
                    style:
                        (expired
                                ? InType.title
                                : InType.title.copyWith(fontSize: 28))
                            .copyWith(height: 1.15, color: c.ink),
                  ),
                  const SizedBox(height: InSpace.s6),
                  Text(
                    expired
                        ? 'Sign in again to keep reading mail on ${expiredInbox.host}.'
                        : 'Your email, on your Cloudflare account. Sign in with the same Access login you use on the web.',
                    textAlign: expired ? TextAlign.center : TextAlign.start,
                    style: InType.body.copyWith(color: c.ink2),
                  ),
                  const SizedBox(height: InSpace.s9),
                  if (!expired) ...[
                    TextField(
                      controller: _url,
                      enabled: !waiting,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (v) => _start(parseInboxUrl(v)),
                      style: InType.mono.copyWith(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Inbox URL',
                        hintText: 'inbox.example.workers.dev',
                        helperText:
                            'The Worker address of your Agentic Inbox deployment.',
                      ),
                    ),
                    const SizedBox(height: InSpace.s7),
                  ],
                  if (waiting) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: InSpace.s6),
                    Text(
                      'Finish signing in in the browser.',
                      style: InType.body.copyWith(color: c.ink2),
                    ),
                    const SizedBox(height: InSpace.s4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: ref.read(signInProvider.notifier).cancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _start(expiredInbox ?? parseInboxUrl(_url.text)),
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: Text(
                          expired
                              ? 'Sign in again'
                              : 'Sign in with Cloudflare Access',
                        ),
                      ),
                    ),
                  if (expired && !waiting)
                    TextButton(
                      onPressed: ref.read(sessionProvider.notifier).signOut,
                      child: const Text('Use a different inbox'),
                    ),
                  if (error != null) ...[
                    const SizedBox(height: InSpace.s7),
                    Text(error, style: InType.body.copyWith(color: c.danger)),
                  ],
                  if (!expired) ...[
                    const SizedBox(height: InSpace.s9),
                    Text(
                      'Access opens in your browser. The app stores only the Access session token, on this device.',
                      style: InType.caption.copyWith(color: c.ink3),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
