import '../models/compose.dart';
import 'client.dart';

class ComposeApi {
  /// Page compose projects
  static Future<List<ComposeItem>> search({int page = 1, int pageSize = 20}) async {
    final res = await ApiClient.instance.post('/containers/compose/search', data: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = res.data['data'] as Map? ?? {};
    final items = (data['items'] as List?)?.map(
      (e) => ComposeItem.fromJson(e as Map<String, dynamic>),
    ).toList() ?? [];
    return items;
  }

  /// Operate compose: start / stop / restart / down
  /// [path] is the docker-compose.yml file path, required for stop/down
  /// [withFile] must be true when [path] is a file path
  static Future<void> operate(String name, String operation,
      {bool force = false, String? path, bool withFile = false}) async {
    final params = <String, dynamic>{
      'name': name,
      'operation': operation,
      'force': force,
    };
    if (path != null && path.isNotEmpty) {
      params['path'] = path;
      params['withFile'] = withFile || true; // always true when path is set
    }
    await ApiClient.instance.post('/containers/compose/operate', data: params);
  }

  /// Update compose file content
  static Future<void> update({
    required String name,
    required String path,
    required String content,
    String? env,
    bool forcePull = false,
  }) async {
    await ApiClient.instance.post('/containers/compose/update', data: {
      'name': name,
      'path': path,
      'content': content,
      'env': env ?? '',
      'forcePull': forcePull,
    });
  }

  /// Test compose file
  static Future<void> test({
    required String name,
    required String file,
    String? env,
    bool forcePull = false,
  }) async {
    await ApiClient.instance.post('/containers/compose/test', data: {
      'name': name,
      'file': file,
      'env': env ?? '',
      'forcePull': forcePull,
    });
  }
}
