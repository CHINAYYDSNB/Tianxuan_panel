import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dashboard_api.dart';
import '../api/container_api.dart';
import '../models/server_status.dart';
import '../models/container.dart';

// ─── 健康阈值配置 ───

class HealthThresholds {
  final int cpuWarning;
  final int cpuCritical;
  final int memWarning;
  final int memCritical;
  final int diskWarning;
  final int diskCritical;

  const HealthThresholds({
    this.cpuWarning = 80,
    this.cpuCritical = 90,
    this.memWarning = 80,
    this.memCritical = 90,
    this.diskWarning = 85,
    this.diskCritical = 95,
  });

  HealthThresholds copyWith({
    int? cpuWarning, int? cpuCritical,
    int? memWarning, int? memCritical,
    int? diskWarning, int? diskCritical,
  }) {
    return HealthThresholds(
      cpuWarning: cpuWarning ?? this.cpuWarning,
      cpuCritical: cpuCritical ?? this.cpuCritical,
      memWarning: memWarning ?? this.memWarning,
      memCritical: memCritical ?? this.memCritical,
      diskWarning: diskWarning ?? this.diskWarning,
      diskCritical: diskCritical ?? this.diskCritical,
    );
  }

  Map<String, dynamic> toJson() => {
    'cpuWarning': cpuWarning, 'cpuCritical': cpuCritical,
    'memWarning': memWarning, 'memCritical': memCritical,
    'diskWarning': diskWarning, 'diskCritical': diskCritical,
  };

  factory HealthThresholds.fromJson(Map<String, dynamic> json) =>
    HealthThresholds(
      cpuWarning: _i(json['cpuWarning'], 80),
      cpuCritical: _i(json['cpuCritical'], 90),
      memWarning: _i(json['memWarning'], 80),
      memCritical: _i(json['memCritical'], 90),
      diskWarning: _i(json['diskWarning'], 85),
      diskCritical: _i(json['diskCritical'], 95),
    );

  static int _i(dynamic v, int d) => (v is num) ? v.toInt() : d;
}

final healthThresholdsProvider = StateProvider<HealthThresholds>((_) => const HealthThresholds());

// ─── 健康状态 ───

enum HealthLevel { ok, warning, critical }

class HealthItem {
  final String label;
  final double value;
  final String unit;
  final HealthLevel level;
  final String detail;

  const HealthItem({
    required this.label,
    required this.value,
    this.unit = '%',
    required this.level,
    this.detail = '',
  });
}

class HealthStatus {
  final List<HealthItem> items;
  final ContainerStatus? containerStatus;
  final DateTime checkedAt;

  const HealthStatus({required this.items, this.containerStatus, required this.checkedAt});

  HealthLevel get overallLevel {
    if (items.any((i) => i.level == HealthLevel.critical)) return HealthLevel.critical;
    if (items.any((i) => i.level == HealthLevel.warning)) return HealthLevel.warning;
    return HealthLevel.ok;
  }

  int get warningCount => items.where((i) => i.level == HealthLevel.warning).length;
  int get criticalCount => items.where((i) => i.level == HealthLevel.critical).length;
}

class HealthNotifier extends AsyncNotifier<HealthStatus> {
  Timer? _timer;

  @override
  Future<HealthStatus> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _autoRefresh());
    ref.onDispose(() => _timer?.cancel());
    return _check();
  }

  Future<HealthStatus> _check() async {
    final thresholds = ref.read(healthThresholdsProvider);
    final items = <HealthItem>[];

    // Dashboard stats
    ServerStatus? status;
    try {
      status = await DashboardApi.getStatus();
    } catch (_) {}

    if (status != null) {
      final cpu = status.cpuUsage;
      items.add(HealthItem(
        label: 'CPU',
        value: cpu,
        level: cpu >= thresholds.cpuCritical ? HealthLevel.critical
             : cpu >= thresholds.cpuWarning ? HealthLevel.warning
             : HealthLevel.ok,
        detail: '${cpu.toStringAsFixed(1)}% / ${thresholds.cpuWarning}%告警线',
      ));

      final mem = status.memoryUsage;
      items.add(HealthItem(
        label: '内存',
        value: mem,
        level: mem >= thresholds.memCritical ? HealthLevel.critical
             : mem >= thresholds.memWarning ? HealthLevel.warning
             : HealthLevel.ok,
        detail: '${mem.toStringAsFixed(1)}% / ${thresholds.memWarning}%告警线',
      ));

      final disk = status.diskUsage;
      items.add(HealthItem(
        label: '磁盘',
        value: disk,
        level: disk >= thresholds.diskCritical ? HealthLevel.critical
             : disk >= thresholds.diskWarning ? HealthLevel.warning
             : HealthLevel.ok,
        detail: '${disk.toStringAsFixed(1)}% / ${thresholds.diskWarning}%告警线',
      ));
    }

    // Container status
    ContainerStatus? cs;
    try {
      cs = await ContainerApi.getStatus();
    } catch (_) {}

    if (cs != null) {
      final running = cs.running;
      final total = cs.containerCount;
      final pct = total > 0 ? ((running / total) * 100).toDouble() : 100.0;
      final stopped = total - running;
      items.add(HealthItem(
        label: '容器',
        value: pct,
        level: stopped > 0 ? (stopped > 3 ? HealthLevel.critical : HealthLevel.warning) : HealthLevel.ok,
        detail: '$running/$total 运行中',
      ));
    }

    return HealthStatus(items: items, containerStatus: cs, checkedAt: DateTime.now());
  }

  Future<void> _autoRefresh() async {
    try {
      state = AsyncValue.data(await _check());
    } catch (e, st) {
      if (state is! AsyncData) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _check());
  }
}

final healthProvider = AsyncNotifierProvider<HealthNotifier, HealthStatus>(HealthNotifier.new);
