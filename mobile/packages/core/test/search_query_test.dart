import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse splits operators from free text like the web parser', () {
    final q = SearchQuery.parse(
      'from:priya contract has:attachment in:Inbox is:unread',
    );
    expect(q.params, {
      'from': 'priya',
      'has_attachment': 'true',
      'folder': 'inbox',
      'is_read': 'false',
      'query': 'contract',
    });
  });

  test('parse supports quoted values and dates', () {
    final q = SearchQuery.parse('subject:"Q4 vendor" after:2026-10-01');
    expect(q.params['subject'], 'Q4 vendor');
    expect(q.params['date_start'], startsWith('2026-'));
    expect(q.params.containsKey('query'), isFalse);
    expect(q.highlightTerms, ['Q4 vendor']);
  });

  test('unknown values are ignored and empty input is empty', () {
    expect(
      SearchQuery.parse('is:weird has:nothing before:notadate').params,
      isEmpty,
    );
    expect(SearchQuery.parse('   ').isEmpty, isTrue);
  });
}
