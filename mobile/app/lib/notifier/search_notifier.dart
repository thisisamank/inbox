import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/service_locator.dart';
import '../models/search.dart';

part 'search_notifier.g.dart';

@riverpod
class Search extends _$Search {
  static const pageSize = 25;

  @override
  SearchState build(String mailboxId) => const SearchState();

  Future<void> run(String text) async {
    final query = SearchQuery.parse(text);
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }
    state = SearchState(
      query: query,
      results: state.results,
      total: state.total,
      loading: true,
    );
    try {
      final page = await mail.search(mailboxId, query.params, limit: pageSize);
      if (!ref.mounted || state.query != query) return;
      state = SearchState(
        query: query,
        results: page.threads,
        total: page.total,
      );
    } on Object catch (error) {
      if (!ref.mounted || state.query != query) return;
      state = SearchState(query: query, error: error);
    }
  }

  Future<void> rerun() async {
    final query = state.query;
    if (query == null) return;
    try {
      final page = await mail.search(mailboxId, query.params, limit: pageSize);
      if (!ref.mounted || state.query != query) return;
      state = SearchState(
        query: query,
        results: page.threads,
        total: page.total,
      );
    } on Object catch (_) {}
  }

  Future<void> loadMore() async {
    final current = state;
    final results = current.results;
    final query = current.query;
    if (current.loadingMore ||
        results == null ||
        query == null ||
        !current.hasMore) {
      return;
    }
    state = SearchState(
      query: query,
      results: results,
      total: current.total,
      page: current.page,
      loadingMore: true,
    );
    try {
      final next = await mail.search(
        mailboxId,
        query.params,
        page: current.page + 1,
        limit: pageSize,
      );
      if (!ref.mounted || state.query != query) return;
      final seen = {for (final r in results) r.id};
      state = SearchState(
        query: query,
        results: [
          ...results,
          ...next.threads.where((t) => !seen.contains(t.id)),
        ],
        total: next.total,
        page: current.page + 1,
      );
    } on Object catch (_) {
      if (ref.mounted && state.query == query) state = current;
    }
  }
}
