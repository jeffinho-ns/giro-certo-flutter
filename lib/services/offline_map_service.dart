import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OfflineMapBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const OfflineMapBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  factory OfflineMapBounds.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const OfflineMapBounds(
        north: 90,
        south: -90,
        east: 180,
        west: -180,
      );
    }
    return OfflineMapBounds(
      north: (json['north'] as num?)?.toDouble() ?? 90,
      south: (json['south'] as num?)?.toDouble() ?? -90,
      east: (json['east'] as num?)?.toDouble() ?? 180,
      west: (json['west'] as num?)?.toDouble() ?? -180,
    );
  }

  bool contains(double lat, double lng) {
    return lat <= north && lat >= south && lng <= east && lng >= west;
  }
}

class OfflineMapRegion {
  final String id;
  final String name;
  final String state;
  final String version;
  final int estimatedSizeMb;
  final String? downloadUrl;
  final OfflineMapBounds bounds;

  const OfflineMapRegion({
    required this.id,
    required this.name,
    required this.state,
    required this.version,
    required this.estimatedSizeMb,
    required this.downloadUrl,
    required this.bounds,
  });

  factory OfflineMapRegion.fromJson(Map<String, dynamic> json) {
    return OfflineMapRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      state: json['state'] as String? ?? '',
      version: json['version'] as String? ?? '1',
      estimatedSizeMb: (json['estimatedSizeMb'] as num?)?.toInt() ?? 0,
      downloadUrl: json['downloadUrl'] as String?,
      bounds:
          OfflineMapBounds.fromJson(json['bounds'] as Map<String, dynamic>?),
    );
  }
}

class OfflineMapDownloadStatus {
  final String regionId;
  final String version;
  final int bytesDownloaded;
  final int totalBytes;
  final String localPath;
  final DateTime downloadedAt;

  const OfflineMapDownloadStatus({
    required this.regionId,
    required this.version,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.localPath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'regionId': regionId,
        'version': version,
        'bytesDownloaded': bytesDownloaded,
        'totalBytes': totalBytes,
        'localPath': localPath,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory OfflineMapDownloadStatus.fromJson(Map<String, dynamic> json) {
    return OfflineMapDownloadStatus(
      regionId: json['regionId'] as String,
      version: json['version'] as String,
      bytesDownloaded: (json['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      localPath: json['localPath'] as String,
      downloadedAt: DateTime.tryParse(json['downloadedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class OfflineMapService {
  static const _storageKey = 'offline_map_downloads_v1';
  static const _fallbackBaseUrl = 'https://giro-certo-next.vercel.app/offline';
  static const _minValidPackBytes = 5 * 1024 * 1024; // 5MB minimo para evitar "pack fake"

  static List<OfflineMapRegion> _fallbackRegions() {
    return const [
      OfflineMapRegion(
        id: 'paracambi',
        name: 'Paracambi',
        state: 'RJ',
        version: '2026.04',
        estimatedSizeMb: 120,
        downloadUrl: '$_fallbackBaseUrl/paracambi-2026.04.mbtiles',
      bounds: OfflineMapBounds(
        north: -22.68,
        south: -22.74,
        east: -43.66,
        west: -43.74,
      ),
      ),
      OfflineMapRegion(
        id: 'rio-capital',
        name: 'Rio de Janeiro (Capital)',
        state: 'RJ',
        version: '2026.04',
        estimatedSizeMb: 240,
        downloadUrl: '$_fallbackBaseUrl/rio-capital-2026.04.mbtiles',
      bounds: OfflineMapBounds(
        north: -22.74,
        south: -23.15,
        east: -43.10,
        west: -43.80,
      ),
      ),
      OfflineMapRegion(
        id: 'sp-capital',
        name: 'Sao Paulo (Capital)',
        state: 'SP',
        version: '2026.04',
        estimatedSizeMb: 280,
        downloadUrl: '$_fallbackBaseUrl/sp-capital-2026.04.mbtiles',
      bounds: OfflineMapBounds(
        north: -23.356,
        south: -23.815,
        east: -46.365,
        west: -46.826,
      ),
      ),
    ];
  }

  static Future<List<OfflineMapRegion>> listRegions() async {
    try {
      final rows = await ApiService.getOfflineMapRegions();
      final parsed = rows.map(OfflineMapRegion.fromJson).toList();
      if (parsed.isEmpty) {
        return _fallbackRegions();
      }
      return parsed;
    } catch (_) {
      // Mantém a tela funcional mesmo antes do env do backend estar pronto.
      return _fallbackRegions();
    }
  }

  static Future<Map<String, OfflineMapDownloadStatus>> getLocalDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) {
      return MapEntry(
        key,
        OfflineMapDownloadStatus.fromJson(Map<String, dynamic>.from(value as Map)),
      );
    });
  }

  static Future<void> _saveLocalDownloads(
      Map<String, OfflineMapDownloadStatus> value) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = value.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_storageKey, json.encode(jsonMap));
  }

  static Future<void> downloadRegion(
    OfflineMapRegion region, {
    required void Function(double progress) onProgress,
  }) async {
    final url = region.downloadUrl;
    if (url == null || url.isEmpty) {
      throw Exception('Regiao ainda sem URL de pacote offline configurada.');
    }

    final uri = Uri.parse(url);
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(uri);
    final response = await request.close();
    if (response.statusCode >= 400) {
      throw Exception('Falha no download (${response.statusCode})');
    }

    final declaredSize = response.contentLength;
    if (declaredSize > 0 && declaredSize < _minValidPackBytes) {
      httpClient.close();
      throw Exception(
        'Pacote offline invalido (muito pequeno: ${(declaredSize / (1024 * 1024)).toStringAsFixed(2)} MB).',
      );
    }

    final appDir = await getApplicationDocumentsDirectory();
    final regionDir = Directory('${appDir.path}/offline-maps/${region.id}/${region.version}');
    await regionDir.create(recursive: true);
    final outFile = File('${regionDir.path}/map.mbtiles');
    final sink = outFile.openWrite();

    final total = response.contentLength;
    var downloaded = 0;
    await for (final chunk in response) {
      downloaded += chunk.length;
      sink.add(chunk);
      if (total > 0) {
        onProgress((downloaded / total).clamp(0, 1));
      }
    }
    await sink.flush();
    await sink.close();
    httpClient.close();

    final savedSize = await outFile.length();
    if (savedSize < _minValidPackBytes) {
      try {
        await outFile.delete();
      } catch (_) {}
      throw Exception(
        'Download concluido, mas pacote invalido (${(savedSize / (1024 * 1024)).toStringAsFixed(2)} MB).',
      );
    }

    final current = await getLocalDownloads();
    current[region.id] = OfflineMapDownloadStatus(
      regionId: region.id,
      version: region.version,
      bytesDownloaded: downloaded,
      totalBytes: total > 0 ? total : downloaded,
      localPath: outFile.path,
      downloadedAt: DateTime.now(),
    );
    await _saveLocalDownloads(current);
  }

  static Future<OfflineMapDownloadStatus?> resolveBestLocalMapForPosition({
    required double latitude,
    required double longitude,
  }) async {
    final regions = await listRegions();
    final downloads = await getLocalDownloads();
    final ordered = regions.where((r) => downloads.containsKey(r.id)).toList();

    for (final region in ordered) {
      if (!region.bounds.contains(latitude, longitude)) continue;
      final local = downloads[region.id];
      if (local == null) continue;
      final file = File(local.localPath);
      if (await file.exists()) {
        return local;
      }
    }

    // fallback: retorna qualquer mapa local existente.
    for (final local in downloads.values) {
      final file = File(local.localPath);
      if (await file.exists()) {
        return local;
      }
    }
    return null;
  }
}
