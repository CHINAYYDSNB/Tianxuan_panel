import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/installed_app_provider.dart';

class InstalledDetailPage extends ConsumerWidget {
  final int installId;
  final String appName;

  const InstalledDetailPage({
    super.key,
    required this.installId,
    required this.appName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(installedAppDetailProvider(installId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(appName)),
      body: detail.when(
        data: (app) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status & version
            Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: app.isRunning ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(app.statusLabel,
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                Text('v${app.version}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
                if (app.updateAvailable) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      app.latestVersion != null
                          ? 'v${app.latestVersion} 可用'
                          : '可更新',
                      style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Info
            _InfoSection(title: '基本信息', children: [
              _InfoRow(label: '应用名称', value: app.name),
              _InfoRow(label: '应用 Key', value: app.appKey),
              _InfoRow(label: '当前版本', value: app.version),
              if (app.httpPort > 0)
                _InfoRow(label: 'HTTP 端口', value: app.httpPort.toString()),
              if (app.container.isNotEmpty)
                _InfoRow(label: '容器名称', value: app.container),
            ]),

            const SizedBox(height: 16),

            // Compose path
            if (app.composePath.isNotEmpty) ...[
              _InfoSection(title: 'Compose 文件', children: [
                _InfoRow(label: '路径', value: app.composePath),
              ]),
              const SizedBox(height: 16),
            ],

            // Environment
            if (app.env.isNotEmpty) ...[
              _InfoSection(title: '环境变量 (${app.env.length})', children: [
                ...app.env.entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text('${e.key}:',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                        ),
                        Expanded(
                          child: Text(e.value,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              Text('加载失败: $e'),
              FilledButton.icon(
                onPressed: () => ref.invalidate(installedAppDetailProvider(installId)),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleSmall),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
