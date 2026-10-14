import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../models/mailbox.dart';

part 'folders_notifier.g.dart';

@riverpod
class Folders extends _$Folders {
  @override
  Future<List<Folder>> build(String mailboxId) => mailboxes.folders(mailboxId);

  Future<Folder> create(String name) async {
    final folder = await mailboxes.createFolder(mailboxId, name);
    ref.invalidateSelf();
    return folder;
  }
}

@riverpod
class SelectedFolder extends _$SelectedFolder {
  @override
  String build(String mailboxId) => 'inbox';

  void select(String folderId) => state = folderId;
}
