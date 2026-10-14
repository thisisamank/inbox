import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../models/search.dart';
import '../../models/thread.dart';
import '../../notifier/search_notifier.dart';
import '../../widgets/feedback.dart';
import '../../widgets/thread_row.dart';

const _operators = [
  'from:',
  'to:',
  'subject:',
  'has:attachment',
  'is:unread',
  'in:sent',
  'after:',
  'before:',
];

const _examples = [
  ('from:priya contract', 'Mail from Priya that mentions "contract"'),
  ('subject:"Q4 vendor"', 'An exact phrase in the subject'),
  ('has:attachment in:inbox', 'Inbox mail with attachments'),
  ('is:unread after:2026-10-01', 'Unread mail since a date'),
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.mailboxId});

  final String mailboxId;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _debounce = Debouncer(const Duration(milliseconds: 450));

  Search get _search => ref.read(searchProvider(widget.mailboxId).notifier);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _search.loadMore();
    });
  }

  @override
  void dispose() {
    _debounce.cancel();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _run() {
    _debounce.cancel();
    _search.run(_input.text);
  }

  void _insert(String op) {
    final text = _input.text;
    final glue = text.isEmpty || text.endsWith(' ') ? '' : ' ';
    final insert = op.endsWith(':') ? op : '$op ';
    final next = '$text$glue$insert';
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _focus.requestFocus();
    if (!op.endsWith(':')) _debounce.run(_run);
  }

  Future<void> _open(ThreadSummary t) async {
    final outcome = await context.push<Outcome>(
      Routes.thread(t.ref, folder: t.folderId ?? 'inbox'),
    );
    if (!mounted) return;
    if (outcome != null) showOutcome(context, outcome);
    await _search.rerun();
  }

  @override
  Widget build(BuildContext context) {
    final c = InColors.of(context);
    final state = ref.watch(searchProvider(widget.mailboxId));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: InTitle('Search', subtitle: widget.mailboxId),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              InSpace.gutter,
              0,
              InSpace.gutter,
              InSpace.s5,
            ),
            child: TextField(
              controller: _input,
              focusNode: _focus,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              onChanged: (_) {
                _debounce.run(_run);
                setState(() {});
              },
              onSubmitted: (_) => _run(),
              style: InType.mono.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search mail',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _input.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _input.clear();
                          _run();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: InSpace.gutter),
              itemCount: _operators.length,
              separatorBuilder: (_, _) => const SizedBox(width: InSpace.s4),
              itemBuilder: (_, i) => ActionChip(
                label: Text(
                  _operators[i],
                  style: InType.monoSmall.copyWith(color: c.ink2),
                ),
                side: BorderSide(color: c.line),
                backgroundColor: c.surface,
                onPressed: () => _insert(_operators[i]),
              ),
            ),
          ),
          if (state.loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(child: _body(c, state)),
        ],
      ),
    );
  }

  Widget _body(InColors c, SearchState state) {
    final error = state.error;
    final query = state.query;
    final results = state.results;
    if (error != null) return InFailure(error: error, onRetry: _run);
    if (query == null) {
      return ListView(
        padding: const EdgeInsets.all(InSpace.gutter),
        children: [
          Text(
            'Search by words, or combine filters:',
            style: InType.body.copyWith(color: c.ink2),
          ),
          const SizedBox(height: InSpace.rowGap),
          for (final (example, meaning) in _examples)
            Padding(
              padding: const EdgeInsets.only(bottom: InSpace.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(example, style: InType.mono.copyWith(color: c.ink)),
                  Text(meaning, style: InType.caption.copyWith(color: c.ink3)),
                ],
              ),
            ),
        ],
      );
    }
    if (results == null) return const SizedBox.shrink();
    if (results.isEmpty) {
      return const InEmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        body: 'Try fewer words or another filter.',
      );
    }
    final total = state.total;
    final hasMore = state.hasMore;
    return ListView.separated(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length + 1 + (hasMore ? 1 : 0),
      separatorBuilder: (_, i) =>
          i == 0 ? const SizedBox.shrink() : const Divider(),
      itemBuilder: (context, i) {
        if (i == 0) {
          return InSectionLabel(total == 1 ? '1 result' : '$total results');
        }
        if (i > results.length) {
          return const Padding(
            padding: EdgeInsets.all(InSpace.s8),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final t = results[i - 1];
        return ThreadRow(
          thread: t,
          highlight: query.highlightTerms,
          folderBadge: t.folderName,
          onTap: () => _open(t),
        );
      },
    );
  }
}
