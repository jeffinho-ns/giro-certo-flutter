/// Banner/promoção da loja virtual (área do lojista).
class StoreBanner {
  final String id;
  final String imageUrl;
  final String? title;
  final String? linkUrl;
  final double? discount;
  final bool active;
  final int sortOrder;

  const StoreBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.linkUrl,
    this.discount,
    this.active = true,
    this.sortOrder = 0,
  });

  factory StoreBanner.fromJson(Map<String, dynamic> json) {
    double? toDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return StoreBanner(
      id: (json['id'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      title: json['title']?.toString(),
      linkUrl: json['linkUrl']?.toString(),
      discount: toDoubleOrNull(json['discount']),
      active: json['active'] == null ? true : json['active'] == true,
      sortOrder: toInt(json['sortOrder']),
    );
  }
}
