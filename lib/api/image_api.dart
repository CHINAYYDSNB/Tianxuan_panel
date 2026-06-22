import '../models/image.dart';
import 'client.dart';

class ImageApi {
  /// List all images
  static Future<List<DockerImage>> listAll() async {
    final res = await ApiClient.instance.get('/containers/image/all');
    final data = res.data['data'];
    if (data is List) {
      return data
          .map((e) => DockerImage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Page images with search
  static Future<Map<String, dynamic>> search({
    int page = 1,
    int pageSize = 20,
    String orderBy = 'name',
    String order = 'ascending',
    String? name,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'orderBy': orderBy,
      'order': order,
    };
    if (name != null && name.isNotEmpty) params['name'] = name;
    final res = await ApiClient.instance.post('/containers/image/search', data: params);
    final data = res.data['data'] as Map? ?? {};
    final items = (data['items'] as List?)?.map(
          (e) => DockerImage.fromJson(e as Map<String, dynamic>),
        ) ??
        <DockerImage>[];
    return {'total': data['total'] ?? 0, 'items': items};
  }

  /// Pull image(s)
  static Future<void> pull(List<String> imageNames) async {
    await ApiClient.instance.post('/containers/image/pull', data: {
      'imageName': imageNames,
    });
  }

  /// Remove image(s)
  static Future<void> remove(List<String> ids, {bool force = false}) async {
    await ApiClient.instance.post('/containers/image/remove', data: {
      'names': ids,
      'force': force,
    });
  }
}
