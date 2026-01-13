class Maintenance {
  final String id;
  final String partName;
  final String category; // Óleo, Pneus, Travões, etc.
  final int lastChangeKm;
  final int recommendedChangeKm;
  final int currentKm;
  final double wearPercentage; // 0.0 a 1.0
  final String status; // OK, Atenção, Crítico

  Maintenance({
    required this.id,
    required this.partName,
    required this.category,
    required this.lastChangeKm,
    required this.recommendedChangeKm,
    required this.currentKm,
    required this.wearPercentage,
    required this.status,
  });

  int get remainingKm => recommendedChangeKm - (currentKm - lastChangeKm);
  double get healthPercentage => 1.0 - wearPercentage;
}
