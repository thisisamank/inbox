final _operator = RegExp(
  r'\b(from|to|subject|in|is|has|before|after):(?:"([^"]*?)"|(\S+))',
  caseSensitive: false,
);

class SearchQuery {
  SearchQuery(this.params);

  factory SearchQuery.parse(String input) {
    final params = <String, String>{};
    var remaining = input;
    for (final m in _operator.allMatches(input)) {
      remaining = remaining.replaceFirst(m[0]!, '');
      final value = m[2] ?? m[3]!;
      switch (m[1]!.toLowerCase()) {
        case 'from':
          params['from'] = value;
        case 'to':
          params['to'] = value;
        case 'subject':
          params['subject'] = value;
        case 'in':
          params['folder'] = value.toLowerCase();
        case 'is':
          switch (value.toLowerCase()) {
            case 'unread':
              params['is_read'] = 'false';
            case 'read':
              params['is_read'] = 'true';
            case 'starred':
              params['is_starred'] = 'true';
            case 'unstarred':
              params['is_starred'] = 'false';
          }
        case 'has':
          if (value.toLowerCase() == 'attachment') {
            params['has_attachment'] = 'true';
          }
        case 'before':
          final d = DateTime.tryParse(value);
          if (d != null) params['date_end'] = d.toUtc().toIso8601String();
        case 'after':
          final d = DateTime.tryParse(value);
          if (d != null) params['date_start'] = d.toUtc().toIso8601String();
      }
    }
    final text = remaining.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isNotEmpty) params['query'] = text;
    return SearchQuery(params);
  }

  final Map<String, String> params;

  bool get isEmpty => params.isEmpty;

  List<String> get highlightTerms => [
    for (final w in (params['query'] ?? '').split(' '))
      if (w.length > 1) w,
    if (params['subject'] != null) params['subject']!,
  ];
}
