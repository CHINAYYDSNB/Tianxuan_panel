class AppStoreItem {
  final int id;
  final String name;
  final String key;
  final String description;
  final String status;
  final bool installed;
  final int limit;
  final List<String>? tags;
  final bool gpuSupport;
  final int recommend;
  final String type;
  final bool batchInstallSupport;

  AppStoreItem({
    required this.id,
    required this.name,
    required this.key,
    this.description = '',
    this.status = '',
    this.installed = false,
    this.limit = 0,
    this.tags,
    this.gpuSupport = false,
    this.recommend = 0,
    this.type = '',
    this.batchInstallSupport = false,
  });

  factory AppStoreItem.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return AppStoreItem(
      id: _toInt(json['id']),
      name: s(json['name']),
      key: s(json['key']),
      description: s(json['description']),
      status: s(json['status']),
      installed: json['installed'] == true,
      limit: _toInt(json['limit']),
      tags: json['tags'] is List
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : null,
      gpuSupport: json['gpuSupport'] == true,
      recommend: _toInt(json['recommend']),
      type: s(json['type']),
      batchInstallSupport: json['batchInstallSupport'] == true,
    );
  }
}

class AppDetail {
  final int id;
  final String name;
  final String key;
  final String shortDescZh;
  final String shortDescEn;
  final String description;
  final String icon;
  final String type;
  final String status;
  final bool crossVersionUpdate;
  final int limit;
  final String website;
  final String github;
  final String document;
  final int recommend;
  final String resource;
  final String readMe;
  final int lastModified;
  final String architectures;
  final int memoryRequired;
  final bool gpuSupport;
  final int requiredPanelVersion;
  final bool batchInstallSupport;
  final bool installed;
  final List<String> versions;
  final List<String>? tags;

  AppDetail({
    required this.id,
    required this.name,
    required this.key,
    this.shortDescZh = '',
    this.shortDescEn = '',
    this.description = '',
    this.icon = '',
    this.type = '',
    this.status = '',
    this.crossVersionUpdate = false,
    this.limit = 0,
    this.website = '',
    this.github = '',
    this.document = '',
    this.recommend = 0,
    this.resource = '',
    this.readMe = '',
    this.lastModified = 0,
    this.architectures = '',
    this.memoryRequired = 0,
    this.gpuSupport = false,
    this.requiredPanelVersion = 0,
    this.batchInstallSupport = false,
    this.installed = false,
    this.versions = const [],
    this.tags,
  });

  factory AppDetail.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return AppDetail(
      id: _toInt(json['id']),
      name: s(json['name']),
      key: s(json['key']),
      shortDescZh: s(json['shortDescZh']),
      shortDescEn: s(json['shortDescEn']),
      description: s(json['description']),
      icon: s(json['icon']),
      type: s(json['type']),
      status: s(json['status']),
      crossVersionUpdate: json['crossVersionUpdate'] == true,
      limit: _toInt(json['limit']),
      website: s(json['website']),
      github: s(json['github']),
      document: s(json['document']),
      recommend: _toInt(json['recommend']),
      resource: s(json['resource']),
      readMe: s(json['readMe']),
      lastModified: _toInt(json['lastModified']),
      architectures: s(json['architectures']),
      memoryRequired: _toInt(json['memoryRequired']),
      gpuSupport: json['gpuSupport'] == true,
      requiredPanelVersion: _toInt(json['requiredPanelVersion']),
      batchInstallSupport: json['batchInstallSupport'] == true,
      installed: json['installed'] == true,
      versions: json['versions'] is List
          ? (json['versions'] as List).map((e) => e.toString()).toList()
          : [],
      tags: json['tags'] is List
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is num) return v.toInt();
  return 0;
}
