import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/mailboxes_notifier.dart';

final _localPart = RegExp(r'^[a-z0-9][a-z0-9._+-]*$');

String? validateMailbox({required String local, required String name}) {
  if (!_localPart.hasMatch(local)) {
    return 'Use letters, numbers, dots, dashes or plus signs.';
  }
  if (name.trim().isEmpty) return 'Enter a display name.';
  return null;
}

class NewMailboxSheet extends ConsumerStatefulWidget {
  const NewMailboxSheet({super.key});

  @override
  ConsumerState<NewMailboxSheet> createState() => _NewMailboxSheetState();
}

class _NewMailboxSheetState extends ConsumerState<NewMailboxSheet> {
  final _local = TextEditingController();
  final _name = TextEditingController();
  String? _domain;
  String? _invalid;

  Future<void> _submit(List<String> domains) async {
    final local = _local.text.trim().toLowerCase();
    final problem = validateMailbox(local: local, name: _name.text);
    setState(() => _invalid = problem);
    if (problem != null) return;
    final created = await ref
        .read(mailboxCreationProvider.notifier)
        .create(
          email: '$local@${_domain ?? domains.first}',
          name: _name.text.trim(),
        );
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  void dispose() {
    _local.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final domains = ref.watch(domainsProvider);
    final creation = ref.watch(mailboxCreationProvider);
    final saving = creation.isLoading;
    final error = _invalid ?? (creation.hasError ? '${creation.error}' : null);

    Widget message(String text) => SizedBox(
      height: 160,
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        InSpace.gutter,
        0,
        InSpace.gutter,
        InSpace.gutter + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: switch (domains) {
        AsyncValue(:final error?, hasValue: false) => message('$error'),
        AsyncValue(hasValue: false) => const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
        AsyncValue(:final value) when value!.isEmpty => message(
          'This inbox has no DOMAINS configured in wrangler.jsonc.',
        ),
        AsyncValue(:final value) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New mailbox', style: InType.heading.copyWith(color: c.ink)),
            const SizedBox(height: InSpace.s7),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _local,
                    autofocus: true,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    style: InType.mono.copyWith(fontSize: 14),
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                ),
                const SizedBox(width: InSpace.s4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _domain ?? value!.first,
                    style: InType.mono.copyWith(fontSize: 14, color: c.ink),
                    items: [
                      for (final d in value!)
                        DropdownMenuItem(value: d, child: Text('@$d')),
                    ],
                    onChanged: saving
                        ? null
                        : (d) => setState(() => _domain = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: InSpace.s3),
            Text(
              'Mail for this address reaches the app through your Email Routing rules.',
              style: InType.caption.copyWith(color: c.ink3),
            ),
            const SizedBox(height: InSpace.s7),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            if (error != null) ...[
              const SizedBox(height: InSpace.s6),
              Text(error, style: InType.body.copyWith(color: c.danger)),
            ],
            const SizedBox(height: InSpace.s8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: InSpace.s5),
                Expanded(
                  child: FilledButton(
                    onPressed: saving ? null : () => _submit(value),
                    child: Text(saving ? 'Creating…' : 'Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      },
    );
  }
}
