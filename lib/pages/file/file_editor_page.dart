import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/file_api.dart';

class FileEditorPage extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;

  const FileEditorPage({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  ConsumerState<FileEditorPage> createState() => _FileEditorPageState();
}

class _FileEditorPageState extends ConsumerState<FileEditorPage> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _modified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await FileApi.getContent(widget.filePath);
      if (mounted) {
        setState(() {
          _ctrl.text = item.content ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FileApi.save(widget.filePath, _ctrl.text);
      if (mounted) {
        setState(() {
          _saving = false;
          _modified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_modified) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未保存的修改'),
        content: const Text('内容已修改，是否保存？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'discard'), child: const Text('不保存')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('保存')),
        ],
      ),
    );
    if (result == 'save') {
      await _save();
      return true;
    }
    return result == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_modified,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName, overflow: TextOverflow.ellipsis),
          actions: [
            if (_modified)
              TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_saving ? '保存中...' : '保存'),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$_error', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadContent, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    return TextField(
      controller: _ctrl,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
        hintText: '文件内容为空',
      ),
      onChanged: (_) {
        if (!_modified) setState(() => _modified = true);
      },
    );
  }
}
