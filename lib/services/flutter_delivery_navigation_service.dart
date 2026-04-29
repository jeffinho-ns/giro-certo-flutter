import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationProgress {
  final int consumedIndex;
  final List<LatLng> consumedPoints;
  final List<LatLng> remainingPoints;
  final double offRouteDistanceMeters;

  const NavigationProgress({
    required this.consumedIndex,
    required this.consumedPoints,
    required this.remainingPoints,
    required this.offRouteDistanceMeters,
  });
}

class FlutterDeliveryNavigationService {
  int _offRouteStreak = 0;
  int _lastRerouteMs = 0;

  NavigationProgress updateProgress({
    required LatLng current,
    required List<LatLng> routePoints,
  }) {
    if (routePoints.length < 2) {
      return NavigationProgress(
        consumedIndex: 0,
        consumedPoints: const [],
        remainingPoints: routePoints,
        offRouteDistanceMeters: 9999,
      );
    }
    final snap = _snapToPolyline(current, routePoints);
    final consumedEnd = snap.segmentIndex + 1;
    final consumed = routePoints.take(consumedEnd).toList(growable: false);
    final remaining = routePoints.skip(consumedEnd - 1).toList(growable: false);
    return NavigationProgress(
      consumedIndex: consumedEnd,
      consumedPoints: consumed,
      remainingPoints: remaining,
      offRouteDistanceMeters: snap.distanceMeters,
    );
  }

  bool shouldTriggerReroute({
    required double offRouteDistanceMeters,
    required int nowMs,
    double thresholdMeters = 40,
    int streakNeeded = 2,
    int cooldownMs = 12000,
  }) {
    if (offRouteDistanceMeters > thresholdMeters) {
      _offRouteStreak += 1;
    } else {
      _offRouteStreak = 0;
    }
    if (_offRouteStreak < streakNeeded) return false;
    if (nowMs - _lastRerouteMs < cooldownMs) return false;
    _lastRerouteMs = nowMs;
    _offRouteStreak = 0;
    return true;
  }

  _SnapResult _snapToPolyline(LatLng p, List<LatLng> route) {
    var bestDistance = double.infinity;
    var bestSegment = 0;
    for (var i = 0; i < route.length - 1; i++) {
      final d = _distancePointToSegmentMeters(p, route[i], route[i + 1]);
      if (d < bestDistance) {
        bestDistance = d;
        bestSegment = i;
      }
    }
    return _SnapResult(distanceMeters: bestDistance, segmentIndex: bestSegment);
  }

  double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;
    final abx = bx - ax;
    final aby = by - ay;
    final abLen2 = abx * abx + aby * aby;
    if (abLen2 == 0) return _haversineMeters(p, a);
    final apx = px - ax;
    final apy = py - ay;
    final t = (apx * abx + apy * aby) / abLen2;
    final tc = t.clamp(0.0, 1.0);
    final proj = LatLng(ay + aby * tc, ax + abx * tc);
    return _haversineMeters(p, proj);
  }

  double _haversineMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final q = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earth * math.asin(math.min(1.0, math.sqrt(q)));
  }
}

class _SnapResult {
  final double distanceMeters;
  final int segmentIndex;

  const _SnapResult({required this.distanceMeters, required this.segmentIndex});
}
