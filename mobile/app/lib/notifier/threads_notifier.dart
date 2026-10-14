import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../models/thread.dart';
import 'folders_notifier.dart';

part 'threads_notifier.g.dart';

@riverpod
class Threads extends _$Threads {
  static const pageSize = 25;

  @override
  Future<ThreadList> build(String mailboxId, String folder) async {
    final page = await mail.threads(mailboxId, folder: folder, limit: pageSize);
    return ThreadList(threads: page.threads, total: page.total);
  }

  Future<void> refresh() async {
    ref
      ..invalidateSelf()
      ..invalidate(foldersProvider(mailboxId));
    try {
      await future;
    } on Object catch (_) {}
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final next = await AsyncValue.guard(
      () => mail.threads(
        mailboxId,
        folder: folder,
        page: current.page + 1,
        limit: pageSize,
      ),
    );
    if (!ref.mounted) return;
    state = AsyncData(
      next.hasValue ? current.appended(next.requireValue) : current,
    );
  }

  Future<Outcome> move(
    ThreadSummary thread, {
    required String to,
    required String label,
  }) async {
    final before = _removeLocally(thread);
    try {
      final ids = await mail.move(mailboxId, thread.ref, from: folder, to: to);
      ref.invalidate(foldersProvider(mailboxId));
      return Outcome(
        'Moved to $label',
        undo: () async {
          await mail.moveIds(mailboxId, ids, folder);
          if (ref.mounted) await refresh();
        },
      );
    } on Object {
      if (ref.mounted && before != null) state = AsyncData(before);
      rethrow;
    }
  }

  Future<Outcome> deleteForever(ThreadSummary thread) async {
    final before = _removeLocally(thread);
    try {
      await mail.deleteForever(mailboxId, thread.ref, from: folder);
      ref.invalidate(foldersProvider(mailboxId));
      return const Outcome('Deleted forever');
    } on Object {
      if (ref.mounted && before != null) state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> toggleRead(ThreadSummary thread) async {
    await mail.setRead(mailboxId, thread.ref, read: thread.unread);
    if (ref.mounted) await refresh();
  }

  ThreadList? _removeLocally(ThreadSummary thread) {
    final current = state.value;
    if (current == null) return null;
    state = AsyncData(
      current.copyWith(
        threads: [...current.threads.where((t) => t.id != thread.id)],
        total: current.total > 0 ? current.total - 1 : 0,
      ),
    );
    return current;
  }
}
