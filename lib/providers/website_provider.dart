import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/website_api.dart';
import '../models/website.dart';

class WebsitesNotifier extends AsyncNotifier<List<Website>> {
  Timer? _timer;

  @override
  Future<List<Website>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _autoRefresh());
    ref.onDispose(() => _timer?.cancel());
    return WebsiteApi.getList();
  }

  /// 静默刷新 — 失败时保留旧数据
  Future<void> _autoRefresh() async {
    try {
      final data = await WebsiteApi.getList();
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// 手动刷新 — 显示 loading + 明确错误
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => WebsiteApi.getList());
  }

  Future<void> deleteWebsite(String id) async {
    await WebsiteApi.delete(id);
    try {
      final data = await WebsiteApi.getList();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> operateWebsite(String id, String action) async {
    await WebsiteApi.operate(id, action);
    try {
      final data = await WebsiteApi.getList();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final websitesProvider =
    AsyncNotifierProvider<WebsitesNotifier, List<Website>>(
  WebsitesNotifier.new,
);
