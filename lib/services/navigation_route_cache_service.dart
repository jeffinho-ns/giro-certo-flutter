import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NavigationRouteCacheService {
  static const _keyOrderId = 'nav_route_order_id';
  static const _keyRoutePoints = 'nav_route_points';

  static Future<void> saveRoute({
    required String orderId,
    required List<Map<String, double>> points,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOrderId, orderId);
    await prefs.setString(_keyRoutePoints, jsonEncode(points));
  }

  static Future<List<Map<String, double>>?> loadRoute(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrderId = prefs.getString(_keyOrderId);
    if (savedOrderId != orderId) return null;
    final raw = prefs.getString(_keyRoutePoints);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded
        .whereType<Map>()
        .map((e) => {
              'lat': (e['lat'] as num).toDouble(),
              'lng': (e['lng'] as num).toDouble(),
            })
        .toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOrderId);
    await prefs.remove(_keyRoutePoints);
  }
}
