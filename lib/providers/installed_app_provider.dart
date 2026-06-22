import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/installed_app_api.dart';
import '../models/installed_app.dart';

class InstalledAppListNotifier extends AsyncNotifier<List<InstalledApp>> {
  @override
  Future<List<InstalledApp>> build() async {
    return InstalledAppApi.list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => InstalledAppApi.list());
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
  return InstalledAppApi.getInfo(id);
});
