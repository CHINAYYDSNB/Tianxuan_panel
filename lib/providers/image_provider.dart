import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/image_api.dart';
import '../models/image.dart';

class ImageListNotifier extends AsyncNotifier<List<DockerImage>> {
  Timer? _timer;

  @override
  Future<List<DockerImage>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _autoRefresh());
    ref.onDispose(() => _timer?.cancel());
    return ImageApi.listAll();
  }

  Future<void> _autoRefresh() async {
    try {
      final data = await ImageApi.listAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ImageApi.listAll());
  }

  Future<void> pull(String imageName) async {
    await ImageApi.pull([imageName]);
    await refresh();
  }

  Future<void> remove(List<String> ids) async {
    await ImageApi.remove(ids);
    await refresh();
  }
}

final imageListProvider =
    AsyncNotifierProvider<ImageListNotifier, List<DockerImage>>(
  ImageListNotifier.new,
);
