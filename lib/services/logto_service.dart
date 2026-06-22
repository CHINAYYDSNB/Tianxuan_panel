import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class LogtoService {
  static const _clientId = 'pti5kd1hbra1svpzaq9em';
  static const _authEndpoint = 'https://logto.lingqi.vip/oidc/auth';
  static const _tokenEndpoint = 'https://logto.lingqi.vip/oidc/token';
  static const _scopes = 'openid profile email';

  /// 生成 PKCE 参数
  static ({String verifier, String challenge, String state}) buildPkce() {
    final verifier = _randomBase64(64);
    final challenge = _sha256Base64Url(verifier);
    final state = verifier.substring(0, 32);
    return (verifier: verifier, challenge: challenge, state: state);
  }

  /// 构建 Logto 授权 URL
  static String buildAuthUrl({
    required String verifier,
    required String challenge,
    required String state,
    required String redirectUri,
  }) {
    final params = {
      'client_id': _clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': _scopes,
      'state': state,
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
    };
    return Uri.parse(_authEndpoint).replace(queryParameters: params).toString();
  }

  /// 交换 authorization code → tokens
  static Future<bool> exchangeCode({
    required String code,
    required String verifier,
    required String redirectUri,
    required String state,
    String? expectedState,
  }) async {
    if (state != expectedState) return false;

    try {
      final resp = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': _clientId,
          'code_verifier': verifier,
        },
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        await StorageService.instance.saveLogtoTokens(
          accessToken: data['access_token']?.toString() ?? '',
          refreshToken: data['refresh_token']?.toString() ?? '',
          idToken: data['id_token']?.toString() ?? '',
          expiresIn: data['expires_in'] as int? ?? 3600,
        );
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// 检查是否已登录
  static Future<bool> get isLoggedIn async {
    final token = await StorageService.instance.getLogtoAccessToken();
    final valid = await StorageService.instance.getLogtoTokenValid();
    return (token?.isNotEmpty == true) && valid;
  }

  static String _randomBase64(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '').substring(0, length);
  }

  static String _sha256Base64Url(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
