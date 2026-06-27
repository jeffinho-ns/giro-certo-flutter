/// Produto da loja virtual (área do lojista).
class StoreProduct {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double basePrice;
  final String? photoUrl;
  final bool active;
  final int sortOrder;

  const StoreProduct({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.basePrice,
    this.photoUrl,
    this.active = true,
    this.sortOrder = 0,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return StoreProduct(
      id: (json['id'] ?? '').toString(),
      categoryId: json['categoryId']?.toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      basePrice: toDouble(json['basePrice']),
      photoUrl: json['photoUrl']?.toString(),
      active: json['active'] == null ? true : json['active'] == true,
      sortOrder: toInt(json['sortOrder']),
    );
  }
}
