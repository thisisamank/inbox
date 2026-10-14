import 'dart:convert';

import 'package:api/api.dart';
import 'package:pinenacl/x25519.dart';
import 'package:test/test.dart';

void main() {
  test('loginUrl matches the cloudflared transfer request', () {
    final url = loginUrl(
      Uri.parse('https://inbox.example.dev/some/path'),
      'aud123',
      'pub=',
    );
    expect(url.path, '/cdn-cgi/access/cli');
    expect(url.queryParameters['aud'], 'aud123');
    expect(url.queryParameters['token'], 'pub=');
    expect(url.queryParameters['edge_token_transfer'], 'true');
    expect(url.queryParameters['send_org_token'], 'true');
    final redirect = Uri.parse(url.queryParameters['redirect_url']!);
    expect(redirect.path, '');
    expect(redirect.queryParameters, {'aud': 'aud123', 'token': 'pub='});
  });

  test('openTransfer decrypts a NaCl box from the transfer service', () {
    final client = PrivateKey.generate();
    final server = PrivateKey.generate();
    final sealed = Box(
      myPrivateKey: server,
      theirPublicKey: client.publicKey,
    ).encrypt(Uint8List.fromList(utf8.encode('{"app_token":"jwt"}')));
    final payload = Uint8List.fromList(
      sealed.nonce.asTypedList + sealed.cipherText.asTypedList,
    );
    final serverKey = base64Url
        .encode(server.publicKey.asTypedList)
        .replaceAll('=', '');
    expect(
      utf8.decode(openTransfer(client, serverKey, payload)),
      '{"app_token":"jwt"}',
    );
  });

  test('decodeJwtClaims reads unpadded payloads', () {
    final body = base64Url
        .encode(utf8.encode('{"aud":"x"}'))
        .replaceAll('=', '');
    expect(decodeJwtClaims('h.$body.s')['aud'], 'x');
  });

  test('isAccessRejection detects expired sessions', () {
    expect(isAccessRejection(403, null), isTrue);
    expect(
      isAccessRejection(
        302,
        'https://team.cloudflareaccess.com/cdn-cgi/access/login/x',
      ),
      isTrue,
    );
    expect(isAccessRejection(302, 'https://elsewhere.example/'), isFalse);
    expect(isAccessRejection(200, null), isFalse);
  });
}
