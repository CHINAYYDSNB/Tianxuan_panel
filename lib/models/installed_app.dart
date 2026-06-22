class InstalledApp {
  final int id;
  final String key;
  final String name;

  InstalledApp({
    required this.id,
    required this.key,
    required this.name,
  });

  factory InstalledApp.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return InstalledApp(
      id: _toInt(json['id']),
      key: s(json['key']),
      name: s(json['name']),
    );
  }
}

class InstalledAppDetail {
  final int id;
  final String name;
  final String version;
  final String status;
  final String message;
  final int httpPort;
  final String container;
  final String composePath;
  final String appKey;
  final List<String>? appPorts;
  final Map<String, String> env;

  InstalledAppDetail({
    required this.id,
    this.name = '',
    this.version = '',
    this.status = '',
    this.message = '',
    this.httpPort = 0,
    this.container = '',
    this.composePath = '',
    this.appKey = '',
    this.appPorts,
    this.env = const {},
  });

  factory InstalledAppDetail.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    final envRaw = json['env'];
    final Map<String, String> envMap = {};
    if (envRaw is Map) {
      envRaw.forEach((k, v) => envMap[k.toString()] = v.toString());
    }
    return InstalledAppDetail(
      id: _toInt(json['id']),
      name: s(json['name']),
      version: s(json['version']),
      status: s(json['status']),
      message: s(json['message']),
      httpPort: _toInt(json['httpPort']),
      container: s(json['container']),
      composePath: s(json['composePath']),
      appKey: s(json['appKey']),
      appPorts: json['appPorts'] is List
          ? (json['appPorts'] as List).map((e) => e.toString()).toList()
          : null,
      env: envMap,
    );
  }

  bool get isRunning => status == 'Running';
  bool get isStopped => status == 'Stopped';

  String get statusLabel {
    switch (status) {
      case 'Running': return '运行中';
      case 'Stopped': return '已停止';
      default: return status;
    }
  }
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is num) return v.toInt();
  return 0;
}
