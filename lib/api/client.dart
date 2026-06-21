import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late Dio _dio;
  String _serverUrl = '';
  late final AuthInterceptor _authInterceptor;

  ApiClient._() {
    _authInterceptor = AuthInterceptor();
    _dio = Dio();
    _dio.interceptors.add(_authInterceptor);
    _dio.interceptors.add(ErrorInterceptor());
  }

  static final _instance = ApiClient._();
  static ApiClient get instance => _instance;

  String get serverUrl => _serverUrl;

  void _configure(String serverUrl, String apiKey) {
    _serverUrl = serverUrl;
    _authInterceptor.setApiKey(apiKey);
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
    _dio.options.responseType = ResponseType.json;
    debugPrint('ApiClient configured: serverUrl=$serverUrl, apiKey=${apiKey.substring(0, 4)}...');
  }

  /// 组装完整请求 URL
  String _fullUrl(String path) => '$_serverUrl/api/v2$path';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('server_url') ?? '';
    final key = prefs.getString('api_key') ?? '';
    if (url.isNotEmpty && key.isNotEmpty) {
      _configure(url, key);
    }
  }

  Future<bool> hasConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('server_url') ?? '').isNotEmpty &&
           (prefs.getString('api_key') ?? '').isNotEmpty;
  }

  Future<void> saveConfig(String serverUrl, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', serverUrl);
    await prefs.setString('api_key', apiKey);
    _configure(serverUrl, apiKey);
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) {
    final url = _fullUrl(path);
    debugPrint('GET $url');
    return _dio.get(url, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) {
    final url = _fullUrl(path);
    debugPrint('POST $url');
    return _dio.post(url, data: data);
  }

  Future<Response> delete(String path) {
    final url = _fullUrl(path);
    debugPrint('DELETE $url');
    return _dio.delete(url);
  }
}

/// 1Panel v2 认证拦截器
/// Token = md5('1panel' + API-Key + UnixTimestamp)
class AuthInterceptor extends Interceptor {
  String _apiKey = '';

  void setApiKey(String key) => _apiKey = key;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 如果 _apiKey 为空, 尝试从 SharedPreferences 自救加载
    if (_apiKey.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = prefs.getString('api_key') ?? '';
        if (key.isNotEmpty) {
          _apiKey = key;
          debugPrint('AuthInterceptor: loaded apiKey from SharedPreferences');
        }
      } catch (_) {
        // SharedPreferences 不可用 (测试环境等)
      }
    }

    if (_apiKey.isNotEmpty) {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
      final token = md5.convert(utf8.encode('1panel$_apiKey$timestamp')).toString();
      options.headers['1Panel-Token'] = token;
      options.headers['1Panel-Timestamp'] = timestamp;
    }
    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final msg = switch (err.response?.statusCode) {
      401 => '认证失败，请检查 API Key',
      403 => '权限不足',
      404 => '接口不存在',
      500 => '服务器错误',
      _ => err.message ?? '网络错误',
    };
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      message: msg,
      error: msg,
    ));
  }
}
