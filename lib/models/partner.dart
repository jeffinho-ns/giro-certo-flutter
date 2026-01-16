import 'dart:math' as math;

enum PartnerType {
  store,
  mechanic,
}

class Promotion {
  final String id;
  final String description;
  final String code;
  final double discountPercentage;
  final String? category; // Categoria da peça relacionada (opcional)

  Promotion({
    required this.id,
    required this.description,
    required this.code,
    required this.discountPercentage,
    this.category,
  });
}

class Partner {
  final String id;
  final String name;
  final PartnerType type; // Store ou Mechanic
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final bool isTrusted; // Parceiro verificado/confiável
  final List<String> specialties; // Ex: Óleo, Pneus, Travões
  final List<Promotion> activePromotions;

  Partner({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.isTrusted,
    required this.specialties,
    required this.activePromotions,
  });

  // Calcula a distância em km (fórmula de Haversine)
  double distanceTo(double userLat, double userLng) {
    const double earthRadius = 6371.0; // km
    final dLat = _toRadians(latitude - userLat);
    final dLng = _toRadians(longitude - userLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(userLat)) *
            math.cos(_toRadians(latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}