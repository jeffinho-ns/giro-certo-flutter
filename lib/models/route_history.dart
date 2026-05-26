/// Representa uma rota concluída pelo motociclista.
class RouteHistoryEntry {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final double averageSpeedKmh;
  final List<RoutePoint> path;
  final String? originLabel;
  final String? destinationLabel;
  final RouteCategory category;

  const RouteHistoryEntry({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.averageSpeedKmh,
    required this.path,
    this.originLabel,
    this.destinationLabel,
    this.category = RouteCategory.leisure,
  });

  Duration get duration => endedAt.difference(startedAt);
}

/// Ponto numa rota — usado tanto para o trajeto quanto para mapa de calor.
class RoutePoint {
  final double latitude;
  final double longitude;
  /// Intensidade (0..1) — usada em heatmap delivery (peso por número de entregas
  /// ou tempo gasto na área).
  final double intensity;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    this.intensity = 1.0,
  });
}

enum RouteCategory {
  leisure,
  commute,
  delivery,
  trip,
}

extension RouteCategoryExt on RouteCategory {
  String get label {
    switch (this) {
      case RouteCategory.leisure:
        return 'Lazer';
      case RouteCategory.commute:
        return 'Trabalho/Diário';
      case RouteCategory.delivery:
        return 'Delivery';
      case RouteCategory.trip:
        return 'Viagem';
    }
  }
}

/// Resumo agregado de cobertura geográfica do usuário (para "desbravar o mapa"
/// dos pilotos lazer).
class ExploredRegion {
  final String name;
  final double latitude;
  final double longitude;
  /// Percentual da região já desbravado (0..1).
  final double exploredFraction;
  final int visitCount;

  const ExploredRegion({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.exploredFraction,
    required this.visitCount,
  });
}
