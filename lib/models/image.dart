class DockerImage {
  final String id;
  final String createdAt;
  final bool isUsed;
  final List<String> tags;
  final int size;
  final bool isPinned;
  final String description;

  DockerImage({
    required this.id,
    this.createdAt = '',
    this.isUsed = false,
    this.tags = const [],
    this.size = 0,
    this.isPinned = false,
    this.description = '',
  });

  factory DockerImage.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return DockerImage(
      id: s(json['id']),
      createdAt: s(json['createdAt']),
      isUsed: json['isUsed'] == true,
      tags: json['tags'] is List
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : [],
      size: _toInt(json['size']),
      isPinned: json['isPinned'] == true,
      description: s(json['description']),
    );
  }

  String get shortId => id.length > 12 ? id.substring(7, 19) : id;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get tagLabel => tags.isNotEmpty ? tags.first : shortId;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is num) return v.toInt();
  return 0;
}
