import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/offline_map_service.dart';
import '../../widgets/modern_header.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  List<OfflineMapRegion> _regions = [];
  Map<String, OfflineMapDownloadStatus> _local = {};
  final Map<String, double> _progress = {};
  final Set<String> _downloading = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final regions = await OfflineMapService.listRegions();
      final local = await OfflineMapService.getLocalDownloads();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _local = local;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar regioes offline: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(OfflineMapRegion region) async {
    setState(() {
      _downloading.add(region.id);
      _progress[region.id] = 0;
    });
    try {
      await OfflineMapService.downloadRegion(
        region,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress[region.id] = p);
        },
      );
      final local = await OfflineMapService.getLocalDownloads();
      if (!mounted) return;
      setState(() => _local = local);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mapa offline de ${region.name} baixado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha no download: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading.remove(region.id);
          _progress.remove(region.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ModernHeader(
            title: 'Mapas Offline',
            showBackButton: true,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _regions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final region = _regions[index];
                      final local = _local[region.id];
                      final downloading = _downloading.contains(region.id);
                      final progress = _progress[region.id] ?? 0;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.map),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${region.name} (${region.state})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text('${region.estimatedSizeMb} MB'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Versao ${region.version}'),
                              if (region.downloadUrl != null &&
                                  region.downloadUrl!.isNotEmpty)
                                Text(
                                  'Fonte: ${region.downloadUrl}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (local != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Baixado em ${local.downloadedAt.day.toString().padLeft(2, '0')}/${local.downloadedAt.month.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                Text(
                                  'Tamanho salvo: ${(local.bytesDownloaded / (1024 * 1024)).toStringAsFixed(2)} MB',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (downloading) ...[
                                const SizedBox(height: 10),
                                LinearProgressIndicator(value: progress),
                              ],
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: downloading
                                      ? null
                                      : (region.downloadUrl == null ||
                                              region.downloadUrl!.isEmpty)
                                          ? null
                                          : () => _download(region),
                                  icon: Icon(downloading
                                      ? LucideIcons.loader
                                      : LucideIcons.download),
                                  label: Text(downloading
                                      ? 'Baixando... ${(progress * 100).toStringAsFixed(0)}%'
                                      : local == null
                                          ? 'Baixar mapa'
                                          : 'Atualizar mapa'),
                                ),
                              ),
                              if (region.downloadUrl == null ||
                                  region.downloadUrl!.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Download indisponivel para esta regiao no momento.',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
