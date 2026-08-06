/// Categoria de produtos da loja virtual (área do lojista).
class StoreCategory {
  final String id;
  final String name;
  final int sortOrder;
  final bool active;

  const StoreCategory({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.active = true,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return StoreCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sortOrder: toInt(json['sortOrder']),
      active: json['active'] == null ? true : json['active'] == true,
    );
  }
}
