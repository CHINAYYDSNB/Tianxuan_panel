import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/installed_app_api.dart';
import '../models/installed_app.dart';

/// 有更新的应用 ID 集合
final updatableAppIdsProvider = StateProvider<Set<int>>((_) => {});

class InstalledAppListNotifier extends AsyncNotifier<List<InstalledApp>> {
  Timer? _updateTimer;
  Map<int, String?> _updates = {}; // installId -> latestVersion

  @override
  Future<List<InstalledApp>> build() async {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 10), (_) => _checkAllUpdates());
    ref.onDispose(() => _updateTimer?.cancel());
    final list = await InstalledAppApi.list();
    _checkAllUpdates();
    return list;
  }

  Map<int, String?> get updates => _updates;

  Future<void> _checkAllUpdates() async {
    final ids = <int>{};
    try {
      final list = state.valueOrNull ?? [];
      for (final app in list) {
        try {
          final versions = await InstalledAppApi.getUpdateVersions(app.id);
          if (versions.isNotEmpty) {
            _updates = {..._updates, app.id: versions.first};
            ids.add(app.id);
          }
        } catch (_) {}
      }
    } catch (_) {}
    // 通知 UI 重建
    ref.read(updatableAppIdsProvider.notifier).state = ids;
  }

  Future<void> checkUpdates(int installId) async {
    try {
      final versions = await InstalledAppApi.getUpdateVersions(installId);
      if (versions.isNotEmpty) {
        _updates = {..._updates, installId: versions.first};
        ref.read(updatableAppIdsProvider.notifier).state =
            {...ref.read(updatableAppIdsProvider), installId};
      } else {
        _updates = {..._updates}..remove(installId);
        ref.read(updatableAppIdsProvider.notifier).state =
            {...ref.read(updatableAppIdsProvider)}..remove(installId);
      }
    } catch (_) {}
  }

  bool hasUpdate(int installId) => _updates.containsKey(installId);
  String? latestVersion(int installId) => _updates[installId];

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => InstalledAppApi.list());
    _checkAllUpdates();
  }

  Future<void> operate(int id, String operation) async {
    await InstalledAppApi.operate(id, operation);
    await refresh();
  }
}

final installedAppListProvider =
    AsyncNotifierProvider<InstalledAppListNotifier, List<InstalledApp>>(
  InstalledAppListNotifier.new,
);

/// Installed app detail
final installedAppDetailProvider =
    FutureProvider.family<InstalledAppDetail, int>((ref, id) async {
  final detail = await InstalledAppApi.getInfo(id);
  // 检查更新
  try {
    final versions = await InstalledAppApi.getUpdateVersions(id);
    if (versions.isNotEmpty && versions.first != detail.version) {
      return InstalledAppDetail(
        id: detail.id, name: detail.name, version: detail.version,
        status: detail.status, message: detail.message,
        httpPort: detail.httpPort, container: detail.container,
        composePath: detail.composePath, appKey: detail.appKey,
        appPorts: detail.appPorts, env: detail.env,
        updateAvailable: true, latestVersion: versions.first,
      );
    }
  } catch (_) {}
  return detail;
});
