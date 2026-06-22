import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/website.dart';
import '../../providers/website_provider.dart';
import '../../api/website_api.dart';
import '../../api/file_api.dart';
import '../../api/client.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart'; // 添加后用于外部 App 编辑

class WebsiteDetailPage extends ConsumerWidget {
  final int websiteId;

  const WebsiteDetailPage({super.key, required this.websiteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(websiteDetailProvider(websiteId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.when(
          data: (w) => Text(w.primaryDomain),
          loading: () => const Text('加载中'),
          error: (e, _) => const Text('网站详情'),
        ),
      ),
      body: detailAsync.when(
        data: (website) => _DetailContent(website: website),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败: $e'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(websiteDetailProvider(websiteId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  final Website website;
  const _DetailContent({required this.website});

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.website;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header card
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Domain + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        w.primaryDomain,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    _StatusBadge(status: w.status),
                  ],
                ),
                const SizedBox(height: 8),

                // Info row
                Text('类型: ${w.typeLabel}  |  别名: ${w.alias}',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                if (w.sitePath != null && w.sitePath!.isNotEmpty)
                  Text('路径: ${w.sitePath}', style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),

                // Date
                Text('创建于: ${_fmtDate(w.createdAt)}',
                    style: theme.textTheme.bodySmall),

                const SizedBox(height: 12),

                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ActionChip(
                      icon: w.isRunning ? Icons.stop : Icons.play_arrow,
                      label: w.isRunning ? '停止' : '启动',
                      onPressed: () => _operate(w.isRunning ? 'stop' : 'start'),
                    ),
                    _ActionChip(
                      icon: Icons.refresh,
                      label: '重启',
                      onPressed: () => _operate('restart'),
                    ),
                    _ActionChip(
                      icon: Icons.folder_open,
                      label: '网站目录',
                      onPressed: () => _openDir(context, w),
                    ),
                    _ActionChip(
                      icon: Icons.code,
                      label: '配置文件',
                      onPressed: () => _downloadConfig(context, w),
                    ),
                    _ActionChip(
                      icon: Icons.delete_outline,
                      label: '删除',
                      color: Colors.red,
                      onPressed: () => _delete(context, w),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // TabBar
        TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: '概览'),
            Tab(text: 'SSL'),
            Tab(text: '日志'),
            Tab(text: '备份'),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _OverviewTab(website: w),
              _SslTab(websiteId: w.id),
              _LogTab(websiteId: w.id),
              _BackupTab(websiteId: w.id, websiteName: w.primaryDomain),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _operate(String action) async {
    try {
      await WebsiteApi.operate(widget.website.id, action);
      ref.invalidate(websiteDetailProvider(widget.website.id));
      ref.invalidate(websitesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action == "start" ? "启动" : action == "stop" ? "停止" : "重启"}成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, Website w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${w.primaryDomain} 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await WebsiteApi.delete(w.id);
        ref.invalidate(websitesProvider);
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _openDir(BuildContext context, Website w) async {
    if (w.sitePath == null || w.sitePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网站路径未设置')),
      );
      return;
    }
    // Navigate to file manager with preset path
    // TODO: use Navigator to file manager page with initialPath
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('跳转到: ${w.sitePath}')),
    );
  }

  Future<void> _downloadConfig(BuildContext context, Website w) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在获取配置...')),
      );
      final config = await WebsiteApi.getConfig(w.id, scope: 'all');
      if (config == null || config.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('获取配置为空 (使用默认配置)')),
          );
        }
        return;
      }

      // Save to temp file for external editing
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${w.alias}_nginx.conf');
      await file.writeAsString(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置文件已保存'),
            action: SnackBarAction(
              label: '查看路径',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(file.path)),
                );
              },
            ),
          ),
        );
        // TODO: 添加 share_plus 后启用外部 App 编辑
        // await Share.shareXFiles([XFile(file.path)], text: '${w.alias} 配置文件');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取配置失败: $e')),
        );
      }
    }
  }

  String _fmtDate(String s) {
    try {
      return s.substring(0, 10);
    } catch (_) {
      return s;
    }
  }
}

// ─── Widgets ───

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'Running' => (Colors.green, '运行中'),
      'Stopped' => (Colors.grey, '已停止'),
      'Error' => (Colors.red, '异常'),
      _ => (Colors.orange, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: c),
      label: Text(label, style: TextStyle(color: c)),
      onPressed: onPressed,
      side: BorderSide(color: c.withValues(alpha: 0.3)),
    );
  }
}

// ─── Tabs ───

class _OverviewTab extends StatelessWidget {
  final Website website;
  const _OverviewTab({required this.website});

  @override
  Widget build(BuildContext context) {
    final w = website;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard(context, '基本配置', [
          _infoTile('状态', w.statusLabel),
          _infoTile('类型', w.typeLabel),
          _infoTile('域名', w.primaryDomain),
          _infoTile('别名', w.alias),
          if (w.remark != null && w.remark!.isNotEmpty) _infoTile('备注', w.remark!),
          if (w.proxy != null && w.proxy!.isNotEmpty) _infoTile('代理地址', w.proxy!),
          if (w.sitePath != null && w.sitePath!.isNotEmpty) _infoTile('网站路径', w.sitePath!),
          if (w.port > 0) _infoTile('端口', w.port.toString()),
        ]),
        const SizedBox(height: 12),
        _infoCard(context, '高级配置', [
          _infoTile('运行用户', w.user ?? '-'),
          _infoTile('网站目录', w.siteDir ?? '/'),
          _infoTile('开放 basedir', w.openBaseDir ? '是' : '否'),
          _infoTile('IPV6', w.iPV6 ? '启用' : '禁用'),
          if (w.defaultServer) _infoTile('默认站点', '是'),
        ]),
        const SizedBox(height: 12),
        if (w.domains.isNotEmpty)
          _infoCard(context, '绑定域名 (${w.domains.length})', [
            ...w.domains.map((d) => _infoTile(
                  d.domain,
                  '端口 ${d.port} ${d.ssl ? "(SSL)" : ""}',
                )),
          ]),
        const SizedBox(height: 12),
        _infoCard(context, '日志', [
          _infoTile('访问日志', w.accessLog ? '启用' : '禁用'),
          _infoTile('错误日志', w.errorLog ? '启用' : '禁用'),
          if (w.accessLogPath != null && w.accessLogPath!.isNotEmpty)
            _infoTile('访问日志路径', w.accessLogPath!),
          if (w.errorLogPath != null && w.errorLogPath!.isNotEmpty)
            _infoTile('错误日志路径', w.errorLogPath!),
        ]),
      ],
    );
  }

  Widget _infoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _SslTab extends ConsumerWidget {
  final int websiteId;
  const _SslTab({required this.websiteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final httpsAsync = ref.watch(websiteHttpsProvider(websiteId));
    return httpsAsync.when(
      data: (data) {
        final enable = data['enable'] == true;
        final ssl = data['SSL'] as Map? ?? {};
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: Icon(enable ? Icons.lock : Icons.lock_open,
                    color: enable ? Colors.green : Colors.grey),
                title: Text(enable ? 'HTTPS 已启用' : 'HTTPS 未启用'),
                subtitle: Text(enable ? '证书已配置' : '点击下方按钮配置 SSL 证书'),
              ),
            ),
            if (enable && ssl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('证书信息',
                          style: Theme.of(context).textTheme.titleSmall),
                      const Divider(),
                      _info('域名', ssl['primaryDomain']?.toString() ?? '-'),
                      _info('颁发者', ssl['provider']?.toString() ?? '-'),
                      _info('状态', ssl['status']?.toString() ?? '-'),
                      _info('过期时间', ssl['expireDate']?.toString() ?? '-'),
                      _info('自动续签', ssl['autoRenew'] == true ? '是' : '否'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _LogTab extends ConsumerStatefulWidget {
  final int websiteId;
  const _LogTab({required this.websiteId});

  @override
  ConsumerState<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends ConsumerState<_LogTab> {
  String _logType = 'access';
  Map<String, dynamic>? _logData;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Type toggle
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'access', label: Text('访问日志')),
                  ButtonSegment(value: 'error', label: Text('错误日志')),
                ],
                selected: {_logType},
                onSelectionChanged: (v) {
                  setState(() => _logType = v.first);
                  _loadLog();
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadLog,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Log content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _logData == null
                  ? const Center(child: Text('点击刷新加载日志'))
                  : _logData!['enable'] == true
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            _logData!['content']?.toString() ?? '',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('日志未启用'),
                              if (_logData!['path']?.toString() != null &&
                                  _logData!['path'].toString().isNotEmpty)
                                Text(
                                  '路径: ${_logData!['path']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Future<void> _loadLog() async {
    setState(() => _loading = true);
    try {
      final data = await WebsiteApi.getLog(widget.websiteId, _logType);
      setState(() => _logData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载日志失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _BackupTab extends ConsumerWidget {
  final int websiteId;
  final String websiteName;
  const _BackupTab({required this.websiteId, required this.websiteName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(backupRecordsProvider);

    return Scaffold(
      body: backupsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.backup_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('暂无备份记录', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(backupRecordsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final r = records[i];
                return ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(r.fileName, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '${_fmtSize(r.fileSize)}  |  ${_fmtDate(r.createdAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download, size: 20),
                        onPressed: () async {
                          try {
                            await WebsiteApi.downloadBackup(r.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('下载已开始')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('下载失败: $e')),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20,
                            color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('确认删除'),
                              content: Text('删除备份: ${r.fileName}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(backupRecordsProvider.notifier)
                                .deleteRecord(r.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'create_backup',
        onPressed: () async {
          try {
            await ref.read(backupRecordsProvider.notifier)
                .createBackup(websiteId, websiteName);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('备份已创建')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('创建备份失败: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _fmtDate(String s) {
    try { return s.substring(0, 19).replaceAll('T', ' '); } catch (_) { return s; }
  }

  String _fmtSize(String s) {
    final size = int.tryParse(s);
    if (size == null) return s;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
