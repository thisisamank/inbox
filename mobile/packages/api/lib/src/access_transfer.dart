import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pinenacl/x25519.dart';

import 'access_session.dart';
import 'api_failure.dart';

class AccessTransferTicket {
  AccessTransferTicket._(
    this.loginUrl,
    this._transfer,
    this._key,
    this._baseUrl,
  );

  final Uri loginUrl;
  final AccessTransfer _transfer;
  final PrivateKey _key;
  final Uri _baseUrl;
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<AccessSession> session() => _transfer._await(this);
}

class AccessTransfer {
  AccessTransfer({Dio? dio, this.deadline = const Duration(minutes: 10)})
    : _dio = dio ?? Dio();

  static final Uri store = Uri.parse(
    'https://login.cloudflareaccess.org/transfer/',
  );

  final Dio _dio;
  final Duration deadline;

  Future<AccessTransferTicket> begin(Uri baseUrl) async {
    final aud = await discoverAud(baseUrl);
    final key = PrivateKey.generate();
    return AccessTransferTicket._(
      loginUrl(baseUrl, aud, publicKeyOf(key)),
      this,
      key,
      baseUrl,
    );
  }

  Future<String> discoverAud(Uri baseUrl) async {
    final Response<void> res;
    try {
      res = await _dio.headUri<void>(
        baseUrl,
        options: Options(
          followRedirects: false,
          validateStatus: (_) => true,
          headers: {'cf-access-metadata-request': 'true'},
        ),
      );
    } on DioException catch (error) {
      throw ApiFailure.fromDioException(error);
    }
    final jwt = res.headers.value('cf-access-metadata');
    if (jwt == null) {
      throw ApiFailure(
        code: ApiErrorCode.invalidRequest,
        message: '${baseUrl.host} is not protected by Cloudflare Access.',
      );
    }
    final claims = decodeJwtClaims(jwt);
    final aud = claims['aud'];
    final host = (claims['hostname'] as String?)?.toLowerCase();
    if (host != baseUrl.host.toLowerCase() || aud is! String || aud.isEmpty) {
      throw ApiFailure(
        code: ApiErrorCode.invalidRequest,
        message: 'Access metadata does not match ${baseUrl.host}.',
      );
    }
    return aud;
  }

  Future<AccessSession> _await(AccessTransferTicket ticket) async {
    final key = ticket._key;
    final url = store.resolve(publicKeyOf(key));
    final stop = DateTime.now().add(deadline);
    while (!ticket._cancelled && DateTime.now().isBefore(stop)) {
      final Response<String> res;
      try {
        res = await _dio.getUri<String>(
          url,
          options: Options(
            responseType: ResponseType.plain,
            validateStatus: (_) => true,
            receiveTimeout: const Duration(seconds: 70),
          ),
        );
      } on DioException catch (_) {
        await Future<void>.delayed(const Duration(seconds: 2));
        continue;
      }
      final status = res.statusCode ?? 0;
      if (status >= 500) {
        throw ApiFailure(
          code: ApiErrorCode.internal,
          message: 'Access sign-in failed ($status).',
          status: status,
        );
      }
      if (status != 200) continue;
      final serverKey = res.headers.value('service-public-key');
      if (serverKey == null) {
        throw const ApiFailure(
          code: ApiErrorCode.unknown,
          message: 'Access sent no transfer key.',
        );
      }
      final payload = openTransfer(
        key,
        serverKey,
        base64.decode((res.data ?? '').trim()),
      );
      final token = (jsonDecode(utf8.decode(payload)) as Map)['app_token'];
      if (token is! String || token.isEmpty) {
        throw const ApiFailure(
          code: ApiErrorCode.unknown,
          message: 'Access returned no app token.',
        );
      }
      return AccessSession(baseUrl: ticket._baseUrl, token: token);
    }
    throw ApiFailure(
      code: ApiErrorCode.unknown,
      message: ticket._cancelled ? 'Sign-in cancelled.' : 'Sign-in timed out.',
    );
  }
}

String publicKeyOf(PrivateKey key) =>
    base64Url.encode(key.publicKey.asTypedList);

Uri loginUrl(Uri baseUrl, String aud, String publicKey) {
  final origin = Uri(
    scheme: baseUrl.scheme,
    host: baseUrl.host,
    port: baseUrl.hasPort ? baseUrl.port : null,
  );
  final redirect = origin.replace(
    queryParameters: {'aud': aud, 'token': publicKey},
  );
  return origin.replace(
    path: '/cdn-cgi/access/cli',
    queryParameters: {
      'aud': aud,
      'token': publicKey,
      'redirect_url': redirect.toString(),
      'send_org_token': 'true',
      'edge_token_transfer': 'true',
      'close_interstitial': 'true',
    },
  );
}

Uint8List openTransfer(PrivateKey key, String serverPublicKey, Uint8List data) {
  if (data.length < 24) {
    throw const ApiFailure(
      code: ApiErrorCode.unknown,
      message: 'Access transfer payload is too short.',
    );
  }
  final box = Box(
    myPrivateKey: key,
    theirPublicKey: PublicKey(
      base64Url.decode(base64Url.normalize(serverPublicKey)),
    ),
  );
  return box.decrypt(
    EncryptedMessage(nonce: data.sublist(0, 24), cipherText: data.sublist(24)),
  );
}

Map<String, Object?> decodeJwtClaims(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) {
    throw const ApiFailure(
      code: ApiErrorCode.invalidRequest,
      message: 'Malformed Access metadata.',
    );
  }
  return jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      )
      as Map<String, Object?>;
}
