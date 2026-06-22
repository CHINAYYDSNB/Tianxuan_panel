import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_store_provider.dart';
import '../../models/app_store_item.dart';

class AppDetailPage extends ConsumerWidget {
  final String appKey;
  final String appName;

  const AppDetailPage({
    super.key,
    required this.appKey,
    required this.appName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(appDetailProvider(appKey));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(appName)),
      body: detail.when(
        data: (app) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.apps, size: 28,
                      color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (app.shortDescZh.isNotEmpty)
                        Text(app.shortDescZh,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info chips
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _Chip(label: '类型: ${app.type}'),
                _Chip(label: '架构: ${app.architectures.isNotEmpty ? app.architectures : "通用"}'),
                if (app.memoryRequired > 0)
                  _Chip(label: '内存: ≥${app.memoryRequired}MB'),
                if (app.versions.isNotEmpty)
                  _Chip(label: '最新: ${app.versions.first}'),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if (app.description.isNotEmpty) ...[
              Text('简介', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(app.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],

            // Links
            if (app.website.isNotEmpty || app.github.isNotEmpty || app.document.isNotEmpty) ...[
              Text('链接', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (app.website.isNotEmpty)
                _LinkRow(icon: Icons.language, label: '官网', url: app.website),
              if (app.github.isNotEmpty)
                _LinkRow(icon: Icons.code, label: 'GitHub', url: app.github),
              if (app.document.isNotEmpty)
                _LinkRow(icon: Icons.description, label: '文档', url: app.document),
              const SizedBox(height: 16),
            ],

            // Versions
            Text('可用版本', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (app.versions.isNotEmpty)
              Wrap(
                spacing: 6, runSpacing: 6,
                children: app.versions.take(10).map((v) =>
                  Chip(
                    label: Text(v, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ).toList(),
              ),
            const SizedBox(height: 24),

            // Warning about install from this page
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '安装应用需通过 1Panel 管理页面操作，当前版本暂不支持一键安装。',
                      style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $e',
                  style: theme.textTheme.bodySmall),
              FilledButton.icon(
                onPressed: () => ref.invalidate(appDetailProvider(appKey)),
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

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(url,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
