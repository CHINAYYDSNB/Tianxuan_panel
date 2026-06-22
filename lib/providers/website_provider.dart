import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/website_api.dart';
import '../models/website.dart';

// ─── Website List ───

class WebsitesNotifier extends AsyncNotifier<List<Website>> {
  Timer? _timer;

  @override
  Future<List<Website>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _autoRefresh());
    ref.onDispose(() => _timer?.cancel());
    return WebsiteApi.getList();
  }

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

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => WebsiteApi.getList());
  }

  Future<void> deleteWebsite(int id) async {
    await WebsiteApi.delete(id);
    await refresh();
  }

  Future<void> operateWebsite(int id, String action) async {
    await WebsiteApi.operate(id, action);
    await refresh();
  }
}

final websitesProvider =
    AsyncNotifierProvider<WebsitesNotifier, List<Website>>(
  WebsitesNotifier.new,
);

// ─── Website Detail ───

final websiteDetailProvider =
    FutureProvider.family<Website, int>((ref, id) async {
  return WebsiteApi.getDetail(id);
});

// ─── Nginx Config ───

final websiteConfigProvider =
    FutureProvider.family<String?, int>((ref, id) async {
  return WebsiteApi.getConfig(id);
});

// ─── HTTPS ───

final websiteHttpsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  return WebsiteApi.getHttps(id);
});

// ─── Log ───

final websiteLogProvider =
    FutureProvider.family<Map<String, dynamic>, ({int id, String logType})>(
        (ref, params) async {
  return WebsiteApi.getLog(params.id, params.logType);
});

// ─── Directory ───

final websiteDirProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  return WebsiteApi.getDir(id);
});

// ─── Backups ───

class BackupRecordsNotifier extends AsyncNotifier<List<BackupRecord>> {
  int _page = 1;
  int _total = 0;

  int get total => _total;
  bool get hasMore => _page * 20 < _total;

  @override
  Future<List<BackupRecord>> build() async {
    _page = 1;
    _total = 0;
    final result = await WebsiteApi.getBackups(1, 20);
    _total = result['total'] as int? ?? 0;
    return result['items'] as List<BackupRecord>? ?? [];
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    _page++;
    final result = await WebsiteApi.getBackups(_page, 20);
    _total = result['total'] as int? ?? 0;
    final newItems = result['items'] as List<BackupRecord>? ?? [];
    state = AsyncValue.data([...state.value ?? [], ...newItems]);
  }

  Future<void> refresh() async {
    _page = 1;
    _total = 0;
    state = const AsyncValue.loading();
    try {
      final result = await WebsiteApi.getBackups(1, 20);
      _total = result['total'] as int? ?? 0;
      state = AsyncValue.data(result['items'] as List<BackupRecord>? ?? []);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecord(int recordId) async {
    await WebsiteApi.deleteBackup(recordId);
    await refresh();
  }

  Future<void> createBackup(int websiteId, String websiteName) async {
    // Get the first available backup account
    final accounts = await WebsiteApi.getBackupAccounts();
    if (accounts.isEmpty) {
      throw Exception('No backup account configured');
    }
    final accountId = accounts.first['id'] as int;
    await WebsiteApi.createBackup(
      websiteId: websiteId,
      websiteName: websiteName,
      backupAccountId: accountId,
    );
    await refresh();
  }
}

final backupRecordsProvider =
    AsyncNotifierProvider<BackupRecordsNotifier, List<BackupRecord>>(
  BackupRecordsNotifier.new,
);

// ─── Create Website ───

final websiteCreateProvider = FutureProvider.family<int, WebsiteCreateRequest>(
  (ref, req) async {
    return WebsiteApi.create(req);
  },
);
