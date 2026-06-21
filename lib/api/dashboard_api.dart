import 'package:dio/dio.dart';
import '../models/server_status.dart';
import 'client.dart';

class DashboardApi {
  static Future<ServerStatus> getStatus() async {
    final Response res = await ApiClient.instance.get('/dashboard/base/0/0');

    // 校验响应体是 JSON，不是 HTML（如请求走错地址被 dev server 拦截）
    if (res.data is! Map) {
      throw Exception('响应格式错误: 期望 JSON, 实际 ${res.data.runtimeType}');
    }

    final body = res.data as Map<String, dynamic>;

    // 检查 1Panel 返回码
    if (body.containsKey('code') && body['code'] != 200) {
      throw Exception(body['message'] ?? '接口返回异常(code=${body['code']})');
    }

    if (body.containsKey('data')) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return ServerStatus.fromJson(data);
      }
    }
    return ServerStatus.fromJson(body);
  }
}
