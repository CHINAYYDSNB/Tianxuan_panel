import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/container_api.dart';
import '../models/container.dart';

// ─── Container List ───

class ContainerListNotifier extends AsyncNotifier<List<Container>> {
  Timer? _timer;

  @override
  Future<List<Container>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _autoRefresh());
    ref.onDispose(() => _timer?.cancel());
    return _fetch();
  }

  Future<List<Container>> _fetch() async {
    final result = await ContainerApi.search(page: 1, pageSize: 50);
    return List<Container>.from(result['items'] ?? []);
  }

  /// 静默刷新 — 失败保留旧数据
  Future<void> _autoRefresh() async {
    try {
      final data = await _fetch();
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// 静默手动刷新 — 不闪 loading
  Future<void> refresh() async {
    try {
      final data = await _fetch();
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> operate(String name, String action) async {
    await ContainerApi.operate(name, action);
    await refresh();
  }
}

final containerListProvider =
    AsyncNotifierProvider<ContainerListNotifier, List<Container>>(
  ContainerListNotifier.new,
);

// ─── Container Stats ───

final containerStatsProvider =
    FutureProvider.family<ContainerStats, String>((ref, name) async {
  return ContainerApi.getStats(name);
});

// ─── Container Status Summary ───

final containerStatusProvider =
    FutureProvider<ContainerStatus>((ref) async {
  return ContainerApi.getStatus();
});
