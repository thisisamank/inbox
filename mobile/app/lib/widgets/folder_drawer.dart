import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../models/mailbox.dart';

class FolderDrawer extends StatelessWidget {
  const FolderDrawer({
    super.key,
    required this.mailboxId,
    required this.folders,
    required this.selected,
    required this.onSelect,
    required this.onNewFolder,
    required this.onSwitchMailbox,
  });

  final String mailboxId;
  final List<Folder> folders;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNewFolder;
  final VoidCallback onSwitchMailbox;

  static const _icons = {
    Folder.inbox: Icons.inbox_outlined,
    Folder.draft: Icons.edit_note,
    Folder.sent: Icons.send_outlined,
    Folder.archive: Icons.archive_outlined,
    Folder.spam: Icons.report_outlined,
    Folder.trash: Icons.delete_outline,
  };

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final byId = {for (final f in folders) f.id: f};
    final system = [
      for (final id in Folder.systemOrder)
        byId[id] ??
            Folder(id: id, name: folderLabel(id, const []), unreadCount: 0),
    ];
    final custom = folders.where((f) => !f.isSystem).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    Widget tile(Folder f, IconData icon) => InNavTile(
      icon: icon,
      label: f.name,
      count: f.id == Folder.sent || f.id == Folder.trash ? 0 : f.unreadCount,
      selected: f.id == selected,
      onTap: () => onSelect(f.id),
    );

    return Drawer(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: InSpace.gutter),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InSpace.s8,
                InSpace.s7,
                InSpace.s8,
                InSpace.s7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mailboxId,
                    style: InType.subheading.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: InSpace.s4),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: onSwitchMailbox,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Switch mailbox'),
                  ),
                ],
              ),
            ),
            for (final f in system) tile(f, _icons[f.id]!),
            if (custom.isNotEmpty) ...[
              const InSectionLabel(
                'Folders',
                padding: EdgeInsets.fromLTRB(
                  InSpace.s8,
                  18,
                  InSpace.s8,
                  InSpace.s3,
                ),
              ),
              for (final f in custom) tile(f, Icons.folder_outlined),
            ],
            InNavTile(
              icon: Icons.create_new_folder_outlined,
              label: 'New folder',
              onTap: onNewFolder,
            ),
          ],
        ),
      ),
    );
  }
}
