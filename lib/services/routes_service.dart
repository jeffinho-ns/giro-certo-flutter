import 'dart:math' as math;
import '../models/route_history.dart';
import 'api_service.dart';

/// Serviço responsável por carregar/gerar o histórico de rotas do usuário.
///
/// No momento, o backend ainda não expõe um endpoint de "histórico de rotas".
/// Esta classe está pronta para integrar com a API (`tryFetchFromApi`) e cai
/// num gerador de dados consistente quando isso falha — assim a UI sempre tem
/// algo para mostrar e a transição para o backend real será transparente.
class RoutesService {
  static const _seedKey = 'giro-routes-seed';

  /// Carrega o histórico do usuário. [isDelivery] muda a "lente":
  /// - delivery: dados focados em entregas (origem/destino e calor)
  /// - lazer: rotas pessoais com viagens, comutes, passeios
  static Future<RoutesData> loadForUser({
    required String userId,
    required bool isDelivery,
    double centerLat = -23.5505,
    double centerLng = -46.6333,
  }) async {
    final apiData = await _tryFetchFromApi(userId: userId, isDelivery: isDelivery);
    if (apiData != null) return apiData;
    return _generateMockData(
      userId: userId,
      isDelivery: isDelivery,
      centerLat: centerLat,
      centerLng: centerLng,
    );
  }

  static Future<RoutesData?> _tryFetchFromApi({
    required String userId,
    required bool isDelivery,
  }) async {
    try {
      // Placeholder: ainda não temos endpoint dedicado. Mantém estrutura para
      // quando o backend expuser /users/:id/routes-history.
      // ignore: unused_local_variable
      final headers = await ApiService.jsonHeadersWithAuth();
      return null;
    } catch (_) {
      return null;
    }
  }

  static RoutesData _generateMockData({
    required String userId,
    required bool isDelivery,
    required double centerLat,
    required double centerLng,
  }) {
    final seed = userId.hashCode ^ _seedKey.hashCode;
    final rng = math.Random(seed);

    if (isDelivery) {
      return _generateDeliveryData(rng, centerLat, centerLng);
    }
    return _generateLeisureData(rng, centerLat, centerLng);
  }

  static RoutesData _generateDeliveryData(
      math.Random rng, double centerLat, double centerLng) {
    final hotspots = <_Hotspot>[
      _Hotspot('Centro', centerLat, centerLng, 1.0),
      _Hotspot('Pinheiros', centerLat - 0.015, centerLng - 0.025, 0.78),
      _Hotspot('Vila Madalena', centerLat + 0.012, centerLng - 0.038, 0.62),
      _Hotspot('Bela Vista', centerLat + 0.005, centerLng + 0.012, 0.85),
      _Hotspot('Consolação', centerLat - 0.008, centerLng - 0.010, 0.71),
      _Hotspot('Itaim Bibi', centerLat - 0.022, centerLng - 0.020, 0.55),
      _Hotspot('Vila Mariana', centerLat + 0.020, centerLng - 0.005, 0.48),
    ];

    final heatmap = <RoutePoint>[];
    for (final h in hotspots) {
      final clusterCount = (h.weight * 70).round();
      for (var i = 0; i < clusterCount; i++) {
        final radius = (1 - h.weight) * 0.015 + rng.nextDouble() * 0.012;
        final angle = rng.nextDouble() * 2 * math.pi;
        heatmap.add(RoutePoint(
          latitude: h.lat + math.cos(angle) * radius,
          longitude: h.lng + math.sin(angle) * radius,
          intensity: (h.weight * (0.5 + rng.nextDouble() * 0.5)).clamp(0.1, 1.0),
        ));
      }
    }

    final now = DateTime.now();
    final history = List<RouteHistoryEntry>.generate(
      8,
      (i) {
        final h = hotspots[i % hotspots.length];
        final start = now.subtract(Duration(hours: 6 + i * 5));
        final durMin = 12 + rng.nextInt(40);
        final distance = 1.2 + rng.nextDouble() * 6;
        final path = <RoutePoint>[];
        for (var s = 0; s < 12; s++) {
          path.add(RoutePoint(
            latitude: h.lat + (rng.nextDouble() - 0.5) * 0.01,
            longitude: h.lng + (rng.nextDouble() - 0.5) * 0.01,
          ));
        }
        return RouteHistoryEntry(
          id: 'd_${i}_${start.millisecondsSinceEpoch}',
          startedAt: start,
          endedAt: start.add(Duration(minutes: durMin)),
          distanceKm: double.parse(distance.toStringAsFixed(1)),
          averageSpeedKmh: 18 + rng.nextDouble() * 12,
          path: path,
          originLabel: h.name,
          destinationLabel: hotspots[(i + 1) % hotspots.length].name,
          category: RouteCategory.delivery,
        );
      },
    );

    final regions = hotspots
        .map((h) => ExploredRegion(
              name: h.name,
              latitude: h.lat,
              longitude: h.lng,
              exploredFraction: h.weight,
              visitCount: (h.weight * 120).round(),
            ))
        .toList();

    return RoutesData(
      heatmapPoints: heatmap,
      history: history,
      regions: regions,
      centerLatitude: centerLat,
      centerLongitude: centerLng,
      profileIsDelivery: true,
      totalDistanceKm: history.fold(0, (a, b) => a + b.distanceKm),
      totalDuration: history.fold<Duration>(
          Duration.zero, (a, b) => a + b.duration),
    );
  }

  static RoutesData _generateLeisureData(
      math.Random rng, double centerLat, double centerLng) {
    final regions = <_Hotspot>[
      _Hotspot('Sé', centerLat, centerLng, 0.85),
      _Hotspot('Vila Madalena', centerLat + 0.013, centerLng - 0.035, 0.74),
      _Hotspot('Mooca', centerLat + 0.005, centerLng + 0.040, 0.32),
      _Hotspot('Santo Amaro', centerLat - 0.070, centerLng - 0.020, 0.45),
      _Hotspot('Tatuapé', centerLat + 0.022, centerLng + 0.045, 0.28),
      _Hotspot('Granja Viana', centerLat + 0.005, centerLng - 0.180, 0.42),
      _Hotspot('Serra do Mar', centerLat - 0.220, centerLng + 0.110, 0.18),
      _Hotspot('Litoral SP', centerLat - 0.380, centerLng + 0.250, 0.12),
    ];

    final exploredPoints = <RoutePoint>[];
    for (final h in regions) {
      final clusters = (h.weight * 35).round();
      for (var i = 0; i < clusters; i++) {
        final radius =
            (rng.nextDouble() * 0.012) + (1 - h.weight) * 0.008;
        final angle = rng.nextDouble() * 2 * math.pi;
        exploredPoints.add(RoutePoint(
          latitude: h.lat + math.cos(angle) * radius,
          longitude: h.lng + math.sin(angle) * radius,
          intensity: (h.weight * 0.9).clamp(0.2, 1.0),
        ));
      }
    }

    final now = DateTime.now();
    final history = <RouteHistoryEntry>[];
    for (var i = 0; i < 7; i++) {
      final origin = regions[i % regions.length];
      final dest = regions[(i + 1) % regions.length];
      final start = now.subtract(Duration(days: i, hours: rng.nextInt(8)));
      final durMin = 25 + rng.nextInt(180);
      final distance = 6 + rng.nextDouble() * 60;
      final path = <RoutePoint>[];
      for (var s = 0; s <= 18; s++) {
        final t = s / 18;
        path.add(RoutePoint(
          latitude: origin.lat + (dest.lat - origin.lat) * t +
              (rng.nextDouble() - 0.5) * 0.005,
          longitude: origin.lng + (dest.lng - origin.lng) * t +
              (rng.nextDouble() - 0.5) * 0.005,
        ));
      }
      history.add(RouteHistoryEntry(
        id: 'r_${i}_${start.millisecondsSinceEpoch}',
        startedAt: start,
        endedAt: start.add(Duration(minutes: durMin)),
        distanceKm: double.parse(distance.toStringAsFixed(1)),
        averageSpeedKmh: 35 + rng.nextDouble() * 40,
        path: path,
        originLabel: origin.name,
        destinationLabel: dest.name,
        category: i == 0
            ? RouteCategory.trip
            : (i % 3 == 0 ? RouteCategory.commute : RouteCategory.leisure),
      ));
    }

    final exploredRegions = regions
        .map((h) => ExploredRegion(
              name: h.name,
              latitude: h.lat,
              longitude: h.lng,
              exploredFraction: h.weight,
              visitCount: (h.weight * 80).round(),
            ))
        .toList();

    return RoutesData(
      heatmapPoints: exploredPoints,
      history: history,
      regions: exploredRegions,
      centerLatitude: centerLat,
      centerLongitude: centerLng,
      profileIsDelivery: false,
      totalDistanceKm: history.fold(0, (a, b) => a + b.distanceKm),
      totalDuration: history.fold<Duration>(
          Duration.zero, (a, b) => a + b.duration),
    );
  }
}

class _Hotspot {
  final String name;
  final double lat;
  final double lng;
  final double weight;

  const _Hotspot(this.name, this.lat, this.lng, this.weight);
}

/// Estrutura agregada com tudo o que a tela de Rotas precisa exibir.
class RoutesData {
  final List<RoutePoint> heatmapPoints;
  final List<RouteHistoryEntry> history;
  final List<ExploredRegion> regions;
  final double centerLatitude;
  final double centerLongitude;
  final bool profileIsDelivery;
  final double totalDistanceKm;
  final Duration totalDuration;

  const RoutesData({
    required this.heatmapPoints,
    required this.history,
    required this.regions,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.profileIsDelivery,
    required this.totalDistanceKm,
    required this.totalDuration,
  });

  bool get isEmpty => heatmapPoints.isEmpty && history.isEmpty;
  double get overallExploredFraction {
    if (regions.isEmpty) return 0;
    final total = regions.fold<double>(0, (a, b) => a + b.exploredFraction);
    return total / regions.length;
  }
}
