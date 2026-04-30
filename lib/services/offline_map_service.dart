import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OfflineMapRegion {
  final String id;
  final String name;
  final String state;
  final String version;
  final int estimatedSizeMb;
  final String? downloadUrl;

  const OfflineMapRegion({
    required this.id,
    required this.name,
    required this.state,
    required this.version,
    required this.estimatedSizeMb,
    required this.downloadUrl,
  });

  factory OfflineMapRegion.fromJson(Map<String, dynamic> json) {
    return OfflineMapRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      state: json['state'] as String? ?? '',
      version: json['version'] as String? ?? '1',
      estimatedSizeMb: (json['estimatedSizeMb'] as num?)?.toInt() ?? 0,
      downloadUrl: json['downloadUrl'] as String?,
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

  static Future<List<OfflineMapRegion>> listRegions() async {
    final rows = await ApiService.getOfflineMapRegions();
    return rows.map(OfflineMapRegion.fromJson).toList();
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

    final appDir = await getApplicationDocumentsDirectory();
    final regionDir = Directory('${appDir.path}/offline-maps/${region.id}/${region.version}');
    await regionDir.create(recursive: true);
    final outFile = File('${regionDir.path}/pack.bin');
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
}
