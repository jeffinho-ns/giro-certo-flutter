class Part {
  final String id;
  final String name;
  final String category; // Performance, Estética, Conforto, Custo-Benefício
  final String brand;
  final double rating;
  final int reviewCount;
  final String description;
  final String? imageUrl;
  final List<String> compatibleModels;

  Part({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.rating,
    required this.reviewCount,
    required this.description,
    this.imageUrl,
    required this.compatibleModels,
  });
}
