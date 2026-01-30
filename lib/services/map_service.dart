import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço para Google Directions API.
/// Configure [apiKey] com a sua chave do Google Maps (Directions API habilitada).
class MapService {
  static const String _directionsBase =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Chave da API Google Maps (compartilhada com Agilizaiapp).
  static String apiKey = 'AIzaSyCYujVw1ifZiGAYCrp30RD4yiB5DFcrj4k';

  /// Obtém os pontos da rota (polyline) entre origem e destino.
  /// Retorna lista de [LatLng] ou vazia em caso de erro.
  static Future<List<Map<String, double>>> getRoutePoints({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final uri = Uri.parse(_directionsBase).replace(
      queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'key': apiKey,
        'mode': 'driving',
      },
    );

    try {
      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout ao obter rota'),
          );

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return [];

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return [];

      final leg = (routes.first as Map<String, dynamic>)['legs'] as List<dynamic>?;
      if (leg == null || leg.isEmpty) return [];

      final steps = (leg.first as Map<String, dynamic>)['steps'] as List<dynamic>?;
      if (steps == null) return [];

      final points = <Map<String, double>>[];
      for (final s in steps) {
        final start = (s as Map<String, dynamic>)['start_location'];
        if (start != null) {
          points.add({
            'lat': (start['lat'] as num).toDouble(),
            'lng': (start['lng'] as num).toDouble(),
          });
        }
        final end = s['end_location'];
        if (end != null) {
          points.add({
            'lat': (end['lat'] as num).toDouble(),
            'lng': (end['lng'] as num).toDouble(),
          });
        }
      }
      // Remover duplicados consecutivos e garantir ordem
      final dedup = <Map<String, double>>[];
      for (final p in points) {
        if (dedup.isEmpty ||
            dedup.last['lat'] != p['lat'] ||
            dedup.last['lng'] != p['lng']) {
          dedup.add(p);
        }
      }
      return dedup;
    } catch (e) {
      return [];
    }
  }
}
