Uri? parseInboxUrl(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
  if (uri == null ||
      uri.host.isEmpty ||
      !uri.host.contains('.') ||
      (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
  );
}
