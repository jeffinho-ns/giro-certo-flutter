/// Conquista desbloqueada pelo utilizador.
class Achievement {
  final String id;
  final String name;
  final String description;
  final String? iconName; // nome do ícone ou asset
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconName: json['iconName'] as String?,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}
