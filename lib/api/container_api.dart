import '../models/container.dart';
import 'client.dart';

class ContainerApi {
  /// Page containers with filters
  static Future<Map<String, dynamic>> search({
    int page = 1,
    int pageSize = 20,
    String state = 'all',
    String orderBy = 'name',
    String order = 'ascending',
    String? name,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'state': state,
      'orderBy': orderBy,
      'order': order,
    };
    if (name != null && name.isNotEmpty) params['name'] = name;
    final res = await ApiClient.instance.post('/containers/search', data: params);
    final data = res.data['data'] as Map? ?? {};
    final items = (data['items'] as List?)?.map(
          (e) => Container.fromJson(e as Map<String, dynamic>),
        ) ??
        <Container>[];
    return {'total': data['total'] ?? 0, 'items': items};
  }

  /// List containers (brief: name + state only)
  static Future<List<Map<String, dynamic>>> list() async {
    final res = await ApiClient.instance.post('/containers/list');
    final data = res.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// Operate container: start / stop / restart / pause / unpause / kill / remove
  static Future<void> operate(String name, String operation) async {
    await ApiClient.instance.post('/containers/operate', data: {
      'names': [name],
      'operation': operation,
    });
  }

  /// Get container stats
  static Future<ContainerStats> getStats(String name) async {
    final res = await ApiClient.instance.get('/containers/stats/$name');
    final raw = res.data['data'];
    final data = (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
    return ContainerStats.fromJson(data);
  }

  /// Get container info (full detail for update)
  static Future<Map<String, dynamic>> getInfo(String name) async {
    final res = await ApiClient.instance.post('/containers/info', data: {
      'name': name,
    });
    final raw = res.data['data'];
    return (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
  }

  /// Rename container
  static Future<void> rename(String name, String newName) async {
    await ApiClient.instance.post('/containers/rename', data: {
      'name': name,
      'newName': newName,
    });
  }

  /// Update container
  static Future<void> update(Map<String, dynamic> data) async {
    await ApiClient.instance.post('/containers/update', data: data);
  }

  /// Upgrade container (pull new image + recreate)
  static Future<void> upgrade(String name, String image, {bool forcePull = true}) async {
    await ApiClient.instance.post('/containers/upgrade', data: {
      'names': [name],
      'image': image,
      'forcePull': forcePull,
    });
  }

  /// Clean container logs
  static Future<void> cleanLog(String name) async {
    await ApiClient.instance.post('/containers/clean/log', data: {
      'name': name,
    });
  }

  /// Get container status summary
  static Future<ContainerStatus> getStatus() async {
    final res = await ApiClient.instance.get('/containers/status');
    final raw = res.data['data'];
    final data = (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
    return ContainerStatus.fromJson(data);
  }
}
