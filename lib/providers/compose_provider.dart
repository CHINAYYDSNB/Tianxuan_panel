import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/compose_api.dart';
import '../models/compose.dart';

class ComposeListNotifier extends AsyncNotifier<List<ComposeItem>> {
  Timer? _timer;

  @override
  Future<List<ComposeItem>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _autoRefresh());
    ref.onDispose(() => _timer?.cancel());
    return ComposeApi.search();
  }

  Future<void> _autoRefresh() async {
    try {
      final data = await ComposeApi.search();
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() async {
    try {
      final data = await ComposeApi.search();
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> operate(String name, String operation, {String? path}) async {
    await ComposeApi.operate(name, operation, path: path);
    await refresh();
  }
}

final composeListProvider =
    AsyncNotifierProvider<ComposeListNotifier, List<ComposeItem>>(
  ComposeListNotifier.new,
);
