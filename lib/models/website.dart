class Website {
  final String id;
  final String domain;
  final String status;
  final String? path;
  final String? phpVersion;
  final String createdAt;

  Website({
    required this.id,
    required this.domain,
    required this.status,
    this.path,
    this.phpVersion,
    required this.createdAt,
  });

  factory Website.fromJson(Map<String, dynamic> json) {
    String safeStr(dynamic v) => v?.toString() ?? '';

    return Website(
      id: safeStr(json['id']),
      domain: safeStr(json['primary_domain'] ?? json['domain'] ?? ''),
      status: safeStr(json['status']),
      path: json['path']?.toString(),
      phpVersion: json['php_version']?.toString(),
      createdAt: safeStr(json['created_at']),
    );
  }
}
