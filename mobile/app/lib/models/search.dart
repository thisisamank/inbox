import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import 'thread.dart';

@immutable
class SearchState {
  const SearchState({
    this.query,
    this.results,
    this.total = 0,
    this.page = 1,
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  final SearchQuery? query;
  final List<ThreadSummary>? results;
  final int total;
  final int page;
  final bool loading;
  final bool loadingMore;
  final Object? error;

  bool get hasMore => (results?.length ?? 0) < total;
}
