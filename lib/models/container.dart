class Container {
  final String containerID;
  final String name;
  final String imageID;
  final String imageName;
  final String createTime;
  final String state;
  final String runTime;
  final List<String> network;
  final List<String>? ports;
  final bool isFromApp;
  final bool isFromCompose;
  final String appName;
  final String appInstallName;
  final String? websites;
  final bool isPinned;
  final String description;

  Container({
    required this.containerID,
    required this.name,
    this.imageID = '',
    this.imageName = '',
    this.createTime = '',
    this.state = '',
    this.runTime = '',
    this.network = const [],
    this.ports,
    this.isFromApp = false,
    this.isFromCompose = false,
    this.appName = '',
    this.appInstallName = '',
    this.websites,
    this.isPinned = false,
    this.description = '',
  });

  factory Container.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return Container(
      containerID: s(json['containerID']),
      name: s(json['name']),
      imageID: s(json['imageID']),
      imageName: s(json['imageName']),
      createTime: s(json['createTime']),
      state: s(json['state']),
      runTime: s(json['runTime']),
      network: json['network'] is List
          ? (json['network'] as List).map((e) => e.toString()).toList()
          : [],
      ports: json['ports'] is List
          ? (json['ports'] as List).map((e) => e.toString()).toList()
          : null,
      isFromApp: json['isFromApp'] == true,
      isFromCompose: json['isFromCompose'] == true,
      appName: s(json['appName']),
      appInstallName: s(json['appInstallName']),
      websites: json['websites']?.toString(),
      isPinned: json['isPinned'] == true,
      description: s(json['description']),
    );
  }

  bool get isRunning => state == 'running';
  bool get isStopped => state == 'exited' || state == 'stopped';
  bool get isPaused => state == 'paused';

  String get stateLabel {
    switch (state) {
      case 'running':
        return '运行中';
      case 'exited':
        return '已停止';
      case 'paused':
        return '已暂停';
      case 'restarting':
        return '重启中';
      case 'removing':
        return '删除中';
      case 'dead':
        return '异常';
      case 'created':
        return '已创建';
      default:
        return state;
    }
  }
}

class ContainerStats {
  final double cpuPercent;
  final double memory;
  final double cache;
  final double ioRead;
  final double ioWrite;
  final double networkRX;
  final double networkTX;
  final String shotTime;

  ContainerStats({
    this.cpuPercent = 0,
    this.memory = 0,
    this.cache = 0,
    this.ioRead = 0,
    this.ioWrite = 0,
    this.networkRX = 0,
    this.networkTX = 0,
    this.shotTime = '',
  });

  factory ContainerStats.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) => (v is num) ? v.toDouble() : 0;
    return ContainerStats(
      cpuPercent: n(json['cpuPercent']),
      memory: n(json['memory']),
      cache: n(json['cache']),
      ioRead: n(json['ioRead']),
      ioWrite: n(json['ioWrite']),
      networkRX: n(json['networkRX']),
      networkTX: n(json['networkTX']),
      shotTime: json['shotTime']?.toString() ?? '',
    );
  }

  String get formattedMemory {
    if (memory < 1) return '${(memory * 1024).toStringAsFixed(0)} MB';
    return '${memory.toStringAsFixed(1)} GB';
  }
}

class ContainerStatus {
  final int created;
  final int running;
  final int paused;
  final int restarting;
  final int removing;
  final int exited;
  final int dead;
  final int containerCount;
  final int composeCount;
  final int composeTemplateCount;
  final int imageCount;
  final int networkCount;
  final int volumeCount;
  final int repoCount;

  ContainerStatus({
    this.created = 0,
    this.running = 0,
    this.paused = 0,
    this.restarting = 0,
    this.removing = 0,
    this.exited = 0,
    this.dead = 0,
    this.containerCount = 0,
    this.composeCount = 0,
    this.composeTemplateCount = 0,
    this.imageCount = 0,
    this.networkCount = 0,
    this.volumeCount = 0,
    this.repoCount = 0,
  });

  factory ContainerStatus.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => (v is int) ? v : (v is num ? v.toInt() : 0);
    return ContainerStatus(
      created: n(json['created']),
      running: n(json['running']),
      paused: n(json['paused']),
      restarting: n(json['restarting']),
      removing: n(json['removing']),
      exited: n(json['exited']),
      dead: n(json['dead']),
      containerCount: n(json['containerCount']),
      composeCount: n(json['composeCount']),
      composeTemplateCount: n(json['composeTemplateCount']),
      imageCount: n(json['imageCount']),
      networkCount: n(json['networkCount']),
      volumeCount: n(json['volumeCount']),
      repoCount: n(json['repoCount']),
    );
  }
}
