import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../models/mailbox.dart';
import '../../models/session_state.dart';
import '../../notifier/mailboxes_notifier.dart';
import '../../notifier/session_notifier.dart';
import '../../widgets/new_mailbox_sheet.dart';

class MailboxesScreen extends ConsumerWidget {
  const MailboxesScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(sessionProvider.notifier).chooseMailbox(id);
    if (context.mounted) context.go(Routes.mail);
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<Mailbox>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const NewMailboxSheet(),
    );
    if (created != null && context.mounted) {
      await _open(context, ref, created.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = InColors.of(context);
    final inbox = switch (ref.watch(sessionProvider).value) {
      SignedIn(:final inbox) => inbox.host,
      _ => null,
    };
    final mailboxes = ref.watch(mailboxesProvider);

    Future<void> refresh() async {
      ref.invalidate(mailboxesProvider);
      try {
        await ref.read(mailboxesProvider.future);
      } on Object catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: InTitle('Mailboxes', subtitle: inbox),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: ref.read(sessionProvider.notifier).signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: switch (mailboxes) {
        AsyncValue(:final error?, hasValue: false) => InFailure(
          error: error,
          onRetry: refresh,
        ),
        AsyncValue(hasValue: false) => const Center(
          child: CircularProgressIndicator(),
        ),
        AsyncValue(:final value) => RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            children: [
              if (value!.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    InSpace.gutter,
                    InSpace.s11,
                    InSpace.gutter,
                    InSpace.s4,
                  ),
                  child: Text(
                    'No mailboxes yet. Create one for any address on your domains.',
                    style: InType.body.copyWith(color: c.ink2),
                  ),
                ),
              for (final item in value) ...[
                ListTile(
                  leading: InAvatar(item.mailbox.email),
                  title: Text(
                    item.mailbox.email,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(switch (item.unread) {
                    null => 'Unread count unavailable',
                    0 => 'No unread mail',
                    final n => '$n unread',
                  }),
                  trailing: Icon(Icons.chevron_right, color: c.ink3),
                  onTap: () => _open(context, ref, item.mailbox.id),
                ),
                const Divider(),
              ],
              Padding(
                padding: const EdgeInsets.all(InSpace.gutter),
                child: OutlinedButton.icon(
                  onPressed: () => _create(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('New mailbox'),
                ),
              ),
            ],
          ),
        ),
      },
    );
  }
}
