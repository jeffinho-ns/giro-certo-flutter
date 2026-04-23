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
  /// `true` quando a geometria veio de vias (Google/OSRM). `false` = linha reta (fallback).
  final bool followsRoads;
  final String? directionsStatus;
  final String? errorMessage;
}

/// Rotas no mapa: backend Giro → Google no app → **OSRM** (OpenStreetMap, sem chave).
class MapService {
  static const String _directionsBase =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String _routesV2Base =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  /// OSRM demo (Project OSRM). Sem API key; geometria segue ruas.
  /// Opcional: `--dart-define=OSRM_BASE_URL=https://seu-servidor/` (deve terminar sem barra final).
  static const String _osrmBase = String.fromEnvironment(
    'OSRM_BASE_URL',
    defaultValue: 'https://router.project-osrm.org',
  );

  /// Chave da Directions API (HTTP no app). Pode falhar por restricao de chave Android-only.
  static String get _directionsApiKey {
    const fromEnv = String.fromEnvironment('GOOGLE_DIRECTIONS_API_KEY');
    final trimmed = fromEnv.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'AIzaSyCYujVw1ifZiGAYCrp30RD4yiB5DFcrj4k';
  }

  /// Obtém os pontos da rota (polyline) entre origem e destino.
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

    final fromBackend = await _tryFetchRouteFromGiroApi(
      originLat: norm.originLat,
      originLng: norm.originLng,
      destLat: norm.destLat,
      destLng: norm.destLng,
    );
    if (fromBackend != null && fromBackend.followsRoads) {
      return fromBackend;
    }

    final google = await _clientGoogleRoutePoints(
      originLat: norm.originLat,
      originLng: norm.originLng,
      destLat: norm.destLat,
      destLng: norm.destLng,
    );
    if (google.followsRoads) return google;

    final osrm = await _tryOsrmRoute(
      originLat: norm.originLat,
      originLng: norm.originLng,
      destLat: norm.destLat,
      destLng: norm.destLng,
    );
    if (osrm != null && osrm.followsRoads) return osrm;

    return google;
  }

  /// OSRM: `lon,lat;lon,lat` + GeoJSON LineString em `geometry.coordinates`.
  static Future<MapRoutePointsResult?> _tryOsrmRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final base = _osrmBase.replaceAll(RegExp(r'/$'), '');
      final path = '$originLng,$originLat;$destLng,$destLat';
      final encodedPath = Uri.encodeComponent(path);
      final uri = Uri.parse('$base/route/v1/driving/$encodedPath').replace(
        queryParameters: const {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );
      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'GiroCerto/1.0 Flutter',
            },
          )
          .timeout(const Duration(seconds: 14));
      if (response.statusCode != 200) {
        debugPrint('OSRM HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
        return null;
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route0 = routes.first as Map<String, dynamic>;
      final geometry = route0['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List<dynamic>?;
      if (coords == null || coords.length < 2) return null;

      final points = <Map<String, double>>[];
      for (final c in coords) {
        if (c is! List<dynamic> || c.length < 2) continue;
        final lon = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        points.add({'lat': lat, 'lng': lon});
      }
      if (points.length < 2) return null;
      return MapRoutePointsResult(
        points: points,
        followsRoads: true,
        directionsStatus: 'OSRM',
      );
    } catch (e) {
      debugPrint('OSRM rota: $e');
      return null;
    }
  }

  static Future<MapRoutePointsResult> _clientGoogleRoutePoints({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final uri = Uri.parse(_directionsBase).replace(
      queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'key': _directionsApiKey,
        'mode': 'driving',
      },
    );

    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'GiroCerto/1.0 Flutter',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout ao obter rota'),
          );

      if (response.statusCode != 200) {
        debugPrint('Directions HTTP ${response.statusCode}: ${response.body}');
        return _fallbackWithRoutesV2(
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
          directionsStatus: 'HTTP_${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        final status = data['status']?.toString() ?? 'UNKNOWN';
        final errorMessage = data['error_message']?.toString() ?? '';
        debugPrint('Directions status=$status error=$errorMessage');
        return _fallbackWithRoutesV2(
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
          directionsStatus: status,
          errorMessage: errorMessage.isEmpty ? null : errorMessage,
        );
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return _fallbackWithRoutesV2(
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
          directionsStatus: 'NO_ROUTES',
        );
      }

      final route = routes.first as Map<String, dynamic>;
      final polyline = (route['overview_polyline']
          as Map<String, dynamic>?)?['points'] as String?;
      final overviewPoints = _decodePolyline(polyline);
      if (overviewPoints.length >= 2) {
        return MapRoutePointsResult(
          points: overviewPoints,
          followsRoads: true,
          directionsStatus: 'OK',
        );
      }

      final stepPoints = _pointsFromRouteLegSteps(route);
      if (stepPoints.length >= 2) {
        return MapRoutePointsResult(
          points: stepPoints,
          followsRoads: true,
          directionsStatus: 'OK',
        );
      }

      final fb = MapRoutePointsResult(
        points: _fallbackRoutePoints(originLat, originLng, destLat, destLng),
        followsRoads: false,
        directionsStatus: 'OK_EMPTY_GEOMETRY',
      );
      final v2 = await _computeRoutesV2Polyline(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );
      return v2.followsRoads ? v2 : fb;
    } catch (e) {
      debugPrint('Erro ao consultar Google Directions: $e');
      final v2 = await _computeRoutesV2Polyline(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );
      if (v2.followsRoads) return v2;
      return MapRoutePointsResult(
        points: _fallbackRoutePoints(originLat, originLng, destLat, destLng),
        followsRoads: false,
        directionsStatus: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  /// Rota calculada no backend (chave Google no Render — evita REQUEST_DENIED no app).
  static Future<MapRoutePointsResult?> _tryFetchRouteFromGiroApi({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
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
          .timeout(const Duration(seconds: 22));
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
    } catch (e) {
      debugPrint('Giro API /maps/directions: $e');
      return null;
    }
  }

  static Future<MapRoutePointsResult> _fallbackWithRoutesV2({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String directionsStatus,
    String? errorMessage,
  }) async {
    final v2 = await _computeRoutesV2Polyline(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
    if (v2.followsRoads) return v2;
    return MapRoutePointsResult(
      points: _fallbackRoutePoints(originLat, originLng, destLat, destLng),
      followsRoads: false,
      directionsStatus: directionsStatus,
      errorMessage: errorMessage,
    );
  }

  static Future<MapRoutePointsResult> _computeRoutesV2Polyline({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    for (final travelMode in ['TWO_WHEELER', 'DRIVE']) {
      try {
        final body = json.encode({
          'origin': {
            'location': {
              'latLng': {'latitude': originLat, 'longitude': originLng},
            },
          },
          'destination': {
            'location': {
              'latLng': {'latitude': destLat, 'longitude': destLng},
            },
          },
          'travelMode': travelMode,
          'polylineQuality': 'HIGH_QUALITY',
          'polylineEncoding': 'ENCODED_POLYLINE',
        });

        final response = await http
            .post(
              Uri.parse(_routesV2Base),
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': _directionsApiKey,
                'X-Goog-FieldMask':
                    'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
                'User-Agent': 'GiroCerto/1.0 Flutter',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          debugPrint(
            'Routes v2 ($travelMode) HTTP ${response.statusCode}: ${response.body}',
          );
          continue;
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['error'] != null) {
          debugPrint('Routes v2 ($travelMode) error: ${data['error']}');
          continue;
        }

        final routes = data['routes'] as List<dynamic>?;
        if (routes == null || routes.isEmpty) continue;

        final route0 = routes.first as Map<String, dynamic>;
        final poly = route0['polyline'] as Map<String, dynamic>?;
        final enc = poly?['encodedPolyline'] as String?;
        final pts = _decodePolyline(enc);
        if (pts.length >= 2) {
          return MapRoutePointsResult(
            points: pts,
            followsRoads: true,
            directionsStatus: 'ROUTES_V2_OK',
          );
        }
      } catch (e) {
        debugPrint('Routes v2 ($travelMode) exception: $e');
      }
    }

    return MapRoutePointsResult(
      points: _fallbackRoutePoints(originLat, originLng, destLat, destLng),
      followsRoads: false,
      directionsStatus: 'ROUTES_V2_FAILED',
    );
  }

  static List<Map<String, double>> _pointsFromRouteLegSteps(
      Map<String, dynamic> route) {
    final legs = route['legs'] as List<dynamic>?;
    if (legs == null || legs.isEmpty) return [];

    final all = <Map<String, double>>[];
    for (final leg in legs) {
      final steps =
          (leg as Map<String, dynamic>)['steps'] as List<dynamic>?;
      if (steps == null) continue;
      for (final step in steps) {
        final poly = (step as Map<String, dynamic>)['polyline']
            as Map<String, dynamic>?;
        final enc = poly?['points'] as String?;
        final segment = _decodePolyline(enc);
        if (segment.isEmpty) continue;
        if (all.isEmpty) {
          all.addAll(segment);
          continue;
        }
        final first = segment.first;
        final last = all.last;
        if (first['lat'] == last['lat'] && first['lng'] == last['lng']) {
          all.addAll(segment.skip(1));
        } else {
          all.addAll(segment);
        }
      }
    }
    return all;
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

  static List<Map<String, double>> _decodePolyline(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];
    try {
      return _decodePolylineImpl(encoded);
    } catch (e, st) {
      debugPrint('Polyline decode: $e $st');
      return [];
    }
  }

  static List<Map<String, double>> _decodePolylineImpl(String encoded) {
    final points = <Map<String, double>>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        if (index >= encoded.length) return points;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      result = 0;
      shift = 0;
      do {
        if (index >= encoded.length) return points;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add({
        'lat': lat / 1e5,
        'lng': lng / 1e5,
      });
    }

    return points;
  }
}
