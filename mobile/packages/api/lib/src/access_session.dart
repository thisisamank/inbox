import 'package:meta/meta.dart';

@immutable
class AccessSession {
  const AccessSession({required this.baseUrl, required this.token});

  static const String cookieName = 'CF_Authorization';

  final Uri baseUrl;
  final String token;

  Map<String, String> get headers => {'Cookie': '$cookieName=$token'};

  @override
  bool operator ==(Object other) =>
      other is AccessSession &&
      other.baseUrl == baseUrl &&
      other.token == token;

  @override
  int get hashCode => Object.hash(baseUrl, token);

  @override
  String toString() => 'AccessSession(${baseUrl.host}, ***)';
}

bool isAccessRejection(int status, String? location) =>
    status == 401 ||
    status == 403 ||
    (status >= 300 &&
        status < 400 &&
        (location ?? '').contains('/cdn-cgi/access/'));
