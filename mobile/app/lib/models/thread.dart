import 'package:flutter/foundation.dart';

@immutable
class ThreadSummary {
  const ThreadSummary({
    required this.id,
    required this.threadId,
    required this.subject,
    required this.sender,
    required this.date,
    required this.read,
    required this.snippet,
    required this.count,
    required this.unreadCount,
    required this.participants,
    required this.hasDraft,
    this.folderId,
    this.folderName,
  });

  final String id;
  final String? threadId;
  final String subject;
  final String sender;
  final DateTime? date;
  final bool read;
  final String snippet;
  final int count;
  final int? unreadCount;
  final String participants;
  final bool hasDraft;
  final String? folderId;
  final String? folderName;

  bool get unread => unreadCount != null ? unreadCount! > 0 : !read;

  ThreadRef get ref => ThreadRef(emailId: id, threadId: threadId);
}

@immutable
class ThreadRef {
  const ThreadRef({required this.emailId, this.threadId});

  final String emailId;
  final String? threadId;

  @override
  bool operator ==(Object other) =>
      other is ThreadRef &&
      other.emailId == emailId &&
      other.threadId == threadId;

  @override
  int get hashCode => Object.hash(emailId, threadId);
}

@immutable
class ThreadPage {
  const ThreadPage({required this.threads, required this.total});

  final List<ThreadSummary> threads;
  final int total;
}

@immutable
class ThreadList {
  const ThreadList({
    required this.threads,
    required this.total,
    this.page = 1,
    this.loadingMore = false,
  });

  final List<ThreadSummary> threads;
  final int total;
  final int page;
  final bool loadingMore;

  bool get hasMore => threads.length < total;

  ThreadList copyWith({
    List<ThreadSummary>? threads,
    int? total,
    int? page,
    bool? loadingMore,
  }) => ThreadList(
    threads: threads ?? this.threads,
    total: total ?? this.total,
    page: page ?? this.page,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  ThreadList appended(ThreadPage next) {
    final seen = {for (final t in threads) t.id};
    return ThreadList(
      threads: [...threads, ...next.threads.where((t) => !seen.contains(t.id))],
      total: next.total,
      page: page + 1,
    );
  }
}

@immutable
class Outcome {
  const Outcome(this.message, {this.undo});

  final String message;
  final Future<void> Function()? undo;
}
