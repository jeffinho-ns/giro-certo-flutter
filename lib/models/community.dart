/// Comunidade (grupo por moto, região, etc.).
class Community {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String createdByUserId;
  final DateTime createdAt;
  final int memberCount;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.createdByUserId,
    required this.createdAt,
    this.memberCount = 0,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdByUserId: json['createdByUserId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      memberCount: (json['memberCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toIso8601String(),
      'memberCount': memberCount,
    };
  }
}
