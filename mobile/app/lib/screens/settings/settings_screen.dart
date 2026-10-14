import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session_state.dart';
import '../../notifier/session_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.mailboxId});

  final String mailboxId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = switch (ref.watch(sessionProvider).value) {
      SignedIn(:final inbox) => inbox.host,
      _ => '',
    };
    final session = ref.read(sessionProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: InTitle('Settings', subtitle: mailboxId),
      ),
      body: ListView(
        children: [
          const InSectionLabel('Account'),
          ListTile(
            title: const Text('Signed in through Access'),
            subtitle: Text(
              inbox,
              style: const TextStyle(fontFamily: InFonts.mono),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch mailbox'),
            onTap: () => session.chooseMailbox(null),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(InSpace.gutter),
            child: OutlinedButton.icon(
              onPressed: session.signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}
