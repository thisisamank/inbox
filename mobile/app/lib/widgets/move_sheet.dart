import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mailbox.dart';
import '../notifier/folders_notifier.dart';

const _systemIcons = {
  Folder.inbox: Icons.inbox_outlined,
  Folder.archive: Icons.archive_outlined,
  Folder.spam: Icons.report_outlined,
  Folder.trash: Icons.delete_outline,
};

Future<String?> showMoveSheet(
  BuildContext context, {
  required String mailboxId,
  required String current,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _MoveSheet(mailboxId: mailboxId, current: current),
);

class _MoveSheet extends ConsumerWidget {
  const _MoveSheet({required this.mailboxId, required this.current});

  final String mailboxId;
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders =
        ref.watch(foldersProvider(mailboxId)).value ?? const <Folder>[];
    final targets = [
      for (final id in Folder.systemOrder)
        if (_systemIcons.containsKey(id) && id != current)
          (id, folderLabel(id, folders), _systemIcons[id]!),
      for (final f in folders.where((f) => !f.isSystem && f.id != current))
        (f.id, f.name, Icons.folder_outlined),
    ];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpace.gutter,
                0,
                InSpace.gutter,
                InSpace.s4,
              ),
              child: Text(
                'Move to',
                style: InType.subheading.copyWith(
                  color: InColors.of(context).ink,
                ),
              ),
            ),
            for (final (id, label, icon) in targets)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(context, id),
              ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New folder…'),
              onTap: () async {
                final folder = await showNewFolderDialog(
                  context,
                  mailboxId: mailboxId,
                );
                if (folder != null && context.mounted) {
                  Navigator.pop(context, folder.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<Folder?> showNewFolderDialog(
  BuildContext context, {
  required String mailboxId,
}) => showDialog<Folder>(
  context: context,
  builder: (_) => _NewFolderDialog(mailboxId: mailboxId),
);

class _NewFolderDialog extends ConsumerStatefulWidget {
  const _NewFolderDialog({required this.mailboxId});

  final String mailboxId;

  @override
  ConsumerState<_NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends ConsumerState<_NewFolderDialog> {
  final _name = TextEditingController();
  String? _error;
  bool _saving = false;

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await AsyncValue.guard(
      () => ref.read(foldersProvider(widget.mailboxId).notifier).create(name),
    );
    if (!mounted) return;
    if (result.hasValue) {
      Navigator.pop(context, result.value);
    } else {
      setState(() {
        _saving = false;
        _error = '${result.error}';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New folder'),
    content: TextField(
      controller: _name,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: (_) => _create(),
      decoration: InputDecoration(labelText: 'Name', errorText: _error),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: _saving ? null : _create,
        child: const Text('Create'),
      ),
    ],
  );
}
