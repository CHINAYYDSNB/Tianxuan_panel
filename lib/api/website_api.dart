import '../models/website.dart';
import 'client.dart';

class WebsiteApi {
  static Future<List<Website>> getList() async {
    final res = await ApiClient.instance.get('/websites/list');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Website.fromJson(e)).toList();
  }

  static Future<void> delete(String id) async {
    await ApiClient.instance.post('/websites/del', data: {'id': id});
  }

  static Future<void> operate(String id, String action) async {
    await ApiClient.instance.post('/websites/operate', data: {
      'id': id,
      'operate': action,
    });
  }
}
