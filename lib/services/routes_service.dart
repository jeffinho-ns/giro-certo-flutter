import '../models/delivery_order.dart';
import '../models/route_history.dart';
import 'api_service.dart';

/// Histórico de rotas a partir de dados reais (entregas concluídas e,
/// quando existir, `/users/me/routes-history`). Sem fallback inventado.
class RoutesService {
  static Future<RoutesData> loadForUser({
    required String userId,
    required bool isDelivery,
    double centerLat = -23.5505,
    double centerLng = -46.6333,
  }) async {
    final fromApi = await _tryFetchUserRoutesHistory();
    if (fromApi != null && !fromApi.isEmpty) {
      return fromApi.copyWith(profileIsDelivery: isDelivery);
    }

    if (userId.isEmpty || userId == 'anon') {
      return RoutesData.empty(
        isDelivery: isDelivery,
        centerLatitude: centerLat,
        centerLongitude: centerLng,
      );
    }

    try {
      final orders = await ApiService.getDeliveryOrders(
        riderId: userId,
        limit: 80,
      );
      final completed = orders
          .where((o) => o.status == DeliveryStatus.completed)
          .toList()
        ..sort((a, b) {
          final aDate = a.completedAt ?? a.createdAt;
          final bDate = b.completedAt ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
      if (completed.isEmpty) {
        return RoutesData.empty(
          isDelivery: isDelivery,
          centerLatitude: centerLat,
          centerLongitude: centerLng,
        );
      }
      return fromCompletedOrders(
        completed,
        isDelivery: isDelivery,
        fallbackLat: centerLat,
        fallbackLng: centerLng,
      );
    } catch (_) {
      return RoutesData.empty(
        isDelivery: isDelivery,
        centerLatitude: centerLat,
        centerLongitude: centerLng,
      );
    }
  }

  static Future<RoutesData?> _tryFetchUserRoutesHistory() async {
    try {
      final raw = await ApiService.getUserRoutesHistory();
      if (raw.isEmpty) return null;
      return RoutesData.fromApiPayload(raw);
    } catch (_) {
      return null;
    }
  }

  static RoutesData fromCompletedOrders(
    List<DeliveryOrder> orders, {
    required bool isDelivery,
    required double fallbackLat,
    required double fallbackLng,
  }) {
    final history = <RouteHistoryEntry>[];
    final heatmap = <RoutePoint>[];
    final regionBuckets = <String, _RegionBucket>{};

    for (final order in orders) {
      final start = order.acceptedAt ?? order.createdAt;
      final end = order.completedAt ?? start.add(Duration(
        minutes: order.estimatedTime ?? 20,
      ));
      final distance = order.distance ?? order.totalDistance;
      final durationMin = end.difference(start).inMinutes.clamp(1, 24 * 60);
      final speed = durationMin > 0 ? (distance / (durationMin / 60)) : 0.0;
      final path = <RoutePoint>[
        RoutePoint(
          latitude: order.storeLatitude,
          longitude: order.storeLongitude,
        ),
        RoutePoint(
          latitude: order.deliveryLatitude,
          longitude: order.deliveryLongitude,
        ),
      ];
      history.add(
        RouteHistoryEntry(
          id: order.id,
          startedAt: start,
          endedAt: end,
          distanceKm: double.parse(distance.toStringAsFixed(1)),
          averageSpeedKmh: speed.clamp(0, 120),
          path: path,
          originLabel: order.storeName,
          destinationLabel: order.deliveryAddress,
          category: RouteCategory.delivery,
        ),
      );
      heatmap.addAll(path.map((p) => RoutePoint(
            latitude: p.latitude,
            longitude: p.longitude,
            intensity: 0.7,
          )));

      final key = order.storeName.trim().isEmpty ? order.storeId : order.storeName;
      final bucket = regionBuckets.putIfAbsent(
        key,
        () => _RegionBucket(
          name: key,
          lat: order.storeLatitude,
          lng: order.storeLongitude,
        ),
      );
      bucket.visitCount += 1;
      bucket.latSum += order.storeLatitude;
      bucket.lngSum += order.storeLongitude;
    }

    final maxVisits = regionBuckets.values.fold<int>(
      1,
      (m, b) => b.visitCount > m ? b.visitCount : m,
    );
    final regions = regionBuckets.values
        .map(
          (b) => ExploredRegion(
            name: b.name,
            latitude: b.latSum / b.visitCount,
            longitude: b.lngSum / b.visitCount,
            exploredFraction: (b.visitCount / maxVisits).clamp(0.1, 1.0),
            visitCount: b.visitCount,
          ),
        )
        .toList()
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));

    final first = orders.first;
    return RoutesData(
      heatmapPoints: heatmap,
      history: history,
      regions: regions,
      centerLatitude: first.storeLatitude != 0 ? first.storeLatitude : fallbackLat,
      centerLongitude:
          first.storeLongitude != 0 ? first.storeLongitude : fallbackLng,
      profileIsDelivery: isDelivery,
      totalDistanceKm: history.fold(0, (a, b) => a + b.distanceKm),
      totalDuration: history.fold<Duration>(
        Duration.zero,
        (a, b) => a + b.duration,
      ),
    );
  }
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class _RegionBucket {
  final String name;
  double latSum;
  double lngSum;
  int visitCount = 0;

  _RegionBucket({
    required this.name,
    required double lat,
    required double lng,
  })  : latSum = lat,
        lngSum = lng;
}

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

  factory RoutesData.empty({
    required bool isDelivery,
    required double centerLatitude,
    required double centerLongitude,
  }) {
    return RoutesData(
      heatmapPoints: const [],
      history: const [],
      regions: const [],
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      profileIsDelivery: isDelivery,
      totalDistanceKm: 0,
      totalDuration: Duration.zero,
    );
  }

  factory RoutesData.fromApiPayload(List<Map<String, dynamic>> raw) {
    final history = <RouteHistoryEntry>[];
    final heatmap = <RoutePoint>[];
    for (final item in raw) {
      final pathRaw = item['path'] as List<dynamic>? ??
          item['points'] as List<dynamic>? ??
          const [];
      final path = pathRaw.whereType<Map>().map((p) {
        final lat = _asDouble(p['lat'] ?? p['latitude']);
        final lng = _asDouble(p['lng'] ?? p['longitude']);
        final intensity = _asDouble(p['intensity'], fallback: 1);
        return RoutePoint(latitude: lat, longitude: lng, intensity: intensity);
      }).where((p) => p.latitude != 0 || p.longitude != 0).toList();
      heatmap.addAll(path);
      final started = DateTime.tryParse(
            (item['startedAt'] ?? item['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now();
      final ended = DateTime.tryParse(
            (item['endedAt'] ?? item['completedAt'] ?? '').toString(),
          ) ??
          started;
      history.add(
        RouteHistoryEntry(
          id: (item['id'] ?? '${started.millisecondsSinceEpoch}').toString(),
          startedAt: started,
          endedAt: ended,
          distanceKm: (item['distanceKm'] as num?)?.toDouble() ?? 0,
          averageSpeedKmh: (item['averageSpeedKmh'] as num?)?.toDouble() ?? 0,
          path: path,
          originLabel: item['originLabel'] as String? ?? item['origin'] as String?,
          destinationLabel:
              item['destinationLabel'] as String? ?? item['destination'] as String?,
          category: RouteCategory.delivery,
        ),
      );
    }
    final center = history.isNotEmpty && history.first.path.isNotEmpty
        ? history.first.path.first
        : const RoutePoint(latitude: -23.5505, longitude: -46.6333);
    return RoutesData(
      heatmapPoints: heatmap,
      history: history,
      regions: const [],
      centerLatitude: center.latitude,
      centerLongitude: center.longitude,
      profileIsDelivery: true,
      totalDistanceKm: history.fold(0, (a, b) => a + b.distanceKm),
      totalDuration: history.fold<Duration>(
        Duration.zero,
        (a, b) => a + b.duration,
      ),
    );
  }

  RoutesData copyWith({bool? profileIsDelivery}) {
    return RoutesData(
      heatmapPoints: heatmapPoints,
      history: history,
      regions: regions,
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      profileIsDelivery: profileIsDelivery ?? this.profileIsDelivery,
      totalDistanceKm: totalDistanceKm,
      totalDuration: totalDuration,
    );
  }

  bool get isEmpty => heatmapPoints.isEmpty && history.isEmpty;
  double get overallExploredFraction {
    if (regions.isEmpty) return 0;
    final total = regions.fold<double>(0, (a, b) => a + b.exploredFraction);
    return total / regions.length;
  }
}
