import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/ring_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _lastUpdated(DateTime t) {
    final sec = DateTime.now().difference(t).inSeconds;
    if (sec < 60) return '${sec}秒前';
    return '${sec ~/ 60}分钟前';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(serverStatusProvider);
    final lastFetch = ref.watch(serverStatusProvider.notifier).lastFetchTime;
    final errMsg = ref.watch(refreshErrorProvider);

    // 网络错误时弹 snackbar
    ref.listen<String?>(refreshErrorProvider, (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $next'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tianxuan - 1Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(serverStatusProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(settingsProvider.notifier).disconnect();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: status.when(
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(serverStatusProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 最后更新时间
              Center(
                child: Text(
                  '最后更新: ${_lastUpdated(lastFetch)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: errMsg != null ? Colors.orange : Colors.grey,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              // 三个环状图
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RingChart(
                    value: data.cpuUsage,
                    label: 'CPU',
                    color: Colors.blue,
                  ),
                  RingChart(
                    value: data.memoryUsage,
                    label: '内存',
                    color: Colors.green,
                    subtitle: '${data.memoryUsed} / ${data.memoryTotal}',
                  ),
                  RingChart(
                    value: data.diskUsage,
                    label: '磁盘',
                    color: Colors.orange,
                    subtitle: '${data.diskUsed} / ${data.diskTotal}',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // 运行时间
              Card(
                child: ListTile(
                  leading: const Icon(Icons.timer_outlined, size: 32),
                  title: Text(ref.watch(tickingUptimeProvider)),
                  subtitle: const Text('运行时间'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$e', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(serverStatusProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
