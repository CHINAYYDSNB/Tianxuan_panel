import '../models/installed_app.dart';
import '../models/app_store_item.dart';
import 'client.dart';

class InstalledAppApi {
  /// List installed apps
  static Future<List<InstalledApp>> list() async {
    final res = await ApiClient.instance.get('/apps/installed/list');
    final data = res.data['data'];
    if (data is List) {
      return data
          .map((e) => InstalledApp.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get installed app detail
  static Future<InstalledAppDetail> getInfo(int id) async {
    final res = await ApiClient.instance.get('/apps/installed/info/$id');
    final raw = res.data['data'];
    final data = (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
    return InstalledAppDetail.fromJson(data);
  }

  /// Operate installed app: start / stop / restart
  static Future<void> operate(int id, String operation) async {
    await ApiClient.instance.post('/apps/installed/op', data: {
      'appInstallID': id,
      'operate': operation,
    });
  }

  /// Install a new app
  static Future<void> install({
    required String key,
    required String name,
    required String version,
    required Map<String, String> params,
  }) async {
    await ApiClient.instance.post('/apps/install', data: {
      'key': key,
      'name': name,
      'version': version,
      'params': params,
    });
  }

  /// Check / get update versions
  static Future<List<String>> getUpdateVersions(int id) async {
    final res = await ApiClient.instance.post('/apps/installed/update/versions', data: {
      'appInstallID': id,
    });
    final data = res.data['data'];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  /// Update config file
  static Future<void> updateConfig(int id, String content) async {
    await ApiClient.instance.post('/apps/installed/config/update', data: {
      'appInstallID': id,
      'content': content,
    });
  }

  /// Update params (env vars)
  static Future<void> updateParams(int id, Map<String, String> params) async {
    await ApiClient.instance.post('/apps/installed/params/update', data: {
      'appInstallID': id,
      'params': params,
    });
  }

  /// Ignore version update
  static Future<void> ignoreUpdate(int id) async {
    await ApiClient.instance.post('/apps/installed/ignore', data: {
      'appInstallID': id,
    });
  }
}
