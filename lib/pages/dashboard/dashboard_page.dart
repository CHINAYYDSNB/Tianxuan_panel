import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/server_list_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/ring_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _lastUpdated(DateTime t) {
    final sec = DateTime.now().difference(t).inSeconds;
    if (sec < 60) return '${sec}秒前';
    return '${sec ~/ 60}分钟前';
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showServerSwitcher(BuildContext context, WidgetRef ref) {
    final servers = ref.read(savedServersProvider);
    final notifier = ref.read(serverStatusProvider.notifier);
    final currUrl = ref.read(settingsProvider).serverUrl ?? '';

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('切换服务器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddServer(context, ref);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加'),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (servers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('暂无已保存的服务器', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...servers.map((s) => ListTile(
                          leading: Icon(
                            s.url == currUrl ? Icons.link : Icons.link_off,
                            color: s.url == currUrl ? Colors.green : Colors.grey,
                          ),
                          title: Text(s.name),
                          subtitle: Text(s.displayUrl, style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (s.url == currUrl)
                                const Chip(label: Text('当前', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () {
                                  final isCurrent = s.url == currUrl;
                                  showDialog(context: ctx, builder: (dCtx) => AlertDialog(
                                    title: const Text('删除服务器'),
                                    content: Text(isCurrent
                                        ? '「${s.name}」是当前服务器, 删除后需重新登录'
                                        : '确定删除「${s.name}」?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('取消')),
                                      TextButton(
                                        onPressed: () {
                                          ref.read(savedServersProvider.notifier).remove(s.id);
                                          Navigator.pop(dCtx);
                                          if (isCurrent && context.mounted) {
                                            ref.read(settingsProvider.notifier).disconnect();
                                            Navigator.pushReplacementNamed(context, '/login');
                                          } else {
                                            setSheetState(() {});
                                          }
                                        },
                                        child: const Text('删除', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ));
                                },
                              ),
                            ],
                          ),
                          onTap: s.url == currUrl
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  final err = await ref.read(savedServersProvider.notifier).switchTo(s);
                                  if (err != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('切换失败: $err'),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                  notifier.refresh();
                                },
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddServer(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();
    final portCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    bool https = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('添加服务器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder(), hintText: '我的服务器')),
                  const SizedBox(height: 12),
                  TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: 'IP 地址', border: OutlineInputBorder(), hintText: '192.168.1.100')),
                  const SizedBox(height: 12),
                  TextField(controller: portCtrl, decoration: const InputDecoration(labelText: '端口', border: OutlineInputBorder(), hintText: '9999'), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder()), obscureText: true),
                  Row(
                    children: [
                      Checkbox(value: https, onChanged: (v) => setSheetState(() => https = v ?? false)),
                      const Text('使用 HTTPS'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final ip = ipCtrl.text.trim();
                        final port = portCtrl.text.trim();
                        final key = keyCtrl.text.trim();
                        if (name.isEmpty || ip.isEmpty || port.isEmpty || key.isEmpty) return;
                        final proto = https ? 'https' : 'http';
                        final url = '$proto://$ip:$port';
                        final id = DateTime.now().millisecondsSinceEpoch.toString();
                        final svr = SavedServer(id: id, name: name, url: url, apiKey: key);
                        // Web 跨域不能直连其他服务器, 跳过测试直接保存
                        if (kIsWeb) {
                          await ref.read(savedServersProvider.notifier).add(svr);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: const Text('已保存, 点击切换即可连接'),
                          ));
                          return;
                        }
                        final err = await ref.read(savedServersProvider.notifier).switchTo(svr, test: true);
                        if (!ctx.mounted) return;
                        if (err != null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('连接测试失败: $err'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        await ref.read(savedServersProvider.notifier).add(svr);
                        Navigator.pop(ctx);
                        ref.read(serverStatusProvider.notifier).refresh();
                      },
                      child: const Text('测试并添加'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              // 服务器信息卡片（点击切换服务器）
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showServerSwitcher(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.dns_outlined, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data.hostname.isNotEmpty ? data.hostname : data.ipv4Address,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (data.platform.isNotEmpty)
                              Chip(
                                label: Text(data.platform, style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                              ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            if (data.cpuModelName.isNotEmpty)
                              _infoChip(Icons.memory, data.cpuModelName),
                            if (data.cpuCores > 0)
                              _infoChip(Icons.developer_board, '${data.cpuCores} 核'),
                            if (data.ipv4Address.isNotEmpty)
                              _infoChip(Icons.language, data.ipv4Address),
                            if (data.kernelVersion.isNotEmpty)
                              _infoChip(Icons.terminal, data.kernelVersion),
                          ],
                        ),
                      ],
                    ),
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
