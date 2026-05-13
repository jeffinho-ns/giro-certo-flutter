import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../utils/geo_coordinates_brazil.dart';

/// Resultado de [MapService.getRoutePoints]: pontos da polyline e se seguem vias (Directions OK).
class MapRoutePointsResult {
  const MapRoutePointsResult({
    required this.points,
    required this.followsRoads,
    this.directionsStatus,
    this.errorMessage,
  });

  final List<Map<String, double>> points;
  /// `true` quando a geometria veio de vias (API Giro). `false` = linha reta ou falha.
  final bool followsRoads;
  final String? directionsStatus;
  final String? errorMessage;
}

/// Preview de rota no mapa Google da home: **uma única** chamada à API Giro (Routes no servidor).
/// Navegação ativa em corrida fica a cargo do Mapbox Navigation SDK.
class MapService {
  static const Duration _previewTimeout = Duration(seconds: 8);

  /// Obtém os pontos da rota (polyline) entre origem e destino — falha rápido sem cascata.
  static Future<MapRoutePointsResult> getRoutePoints({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final norm = GeoCoordinatesBrazil.normalizeRouteEndpoints(
      originLat,
      originLng,
      destLat,
      destLng,
    );

    try {
      final fromBackend = await _fetchRouteFromGiroApi(
        originLat: norm.originLat,
        originLng: norm.originLng,
        destLat: norm.destLat,
        destLng: norm.destLng,
      ).timeout(
        _previewTimeout,
        onTimeout: () => null,
      );
      if (fromBackend != null && fromBackend.followsRoads) {
        return fromBackend;
      }
    } catch (e) {
      debugPrint('MapService preview: $e');
    }

    return MapRoutePointsResult(
      points: _fallbackRoutePoints(
        norm.originLat,
        norm.originLng,
        norm.destLat,
        norm.destLng,
      ),
      followsRoads: false,
      directionsStatus: 'PREVIEW_UNAVAILABLE',
      errorMessage:
          'Nao foi possivel obter a rota de preview. A navegacao Mapbox continua disponivel.',
    );
  }

  static Future<MapRoutePointsResult?> _fetchRouteFromGiroApi({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/maps/directions').replace(
      queryParameters: {
        'originLat': originLat.toString(),
        'originLng': originLng.toString(),
        'destLat': destLat.toString(),
        'destLng': destLng.toString(),
      },
    );
    final headers = await ApiService.jsonHeadersWithAuth();
    final response = await http
        .get(uri, headers: headers)
        .timeout(_previewTimeout);
    if (response.statusCode != 200) {
      debugPrint(
        'Giro API /maps/directions HTTP ${response.statusCode}: ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}',
      );
      return null;
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['followsRoads'] != true) return null;
    final raw = data['points'];
    if (raw is! List<dynamic>) return null;
    final points = <Map<String, double>>[];
    for (final p in raw) {
      if (p is! Map<String, dynamic>) continue;
      final lat = p['lat'];
      final lng = p['lng'];
      if (lat is! num || lng is! num) continue;
      points.add({'lat': lat.toDouble(), 'lng': lng.toDouble()});
    }
    if (points.length < 2) return null;
    return MapRoutePointsResult(
      points: points,
      followsRoads: true,
      directionsStatus: 'GIRO_API',
    );
  }

  static List<Map<String, double>> _fallbackRoutePoints(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) {
    return [
      {'lat': originLat, 'lng': originLng},
      {'lat': destLat, 'lng': destLng},
    ];
  }
}
