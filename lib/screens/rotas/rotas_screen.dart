import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../models/route_history.dart';
import '../../services/routes_service.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';

/// Tela de Rotas:
/// - Pilotos lazer/diário: mapa "desbravado" (fog-of-war) mostrando as áreas
///   já exploradas e o histórico de rotas.
/// - Delivery: mapa de calor com pontos de mais atendimentos.
class RotasScreen extends StatefulWidget {
  const RotasScreen({super.key});

  @override
  State<RotasScreen> createState() => _RotasScreenState();
}

class _RotasScreenState extends State<RotasScreen> {
  RoutesData? _data;
  bool _loading = true;
  String? _error;
  final MapController _mapController = MapController();
  RouteHistoryEntry? _selectedEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await RoutesService.loadForUser(
        userId: user?.id ?? 'anon',
        isDelivery: appState.isDeliveryPilot,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar suas rotas.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Rotas',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError(theme)
                        : _buildContent(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(LucideIcons.cloudOff,
            size: 48, color: AppColors.statusWarning),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _error!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: _load,
            child: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    final data = _data!;
    final isDelivery = data.profileIsDelivery;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildSummaryHeader(data, theme),
        const SizedBox(height: 16),
        _buildMap(data, theme),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            isDelivery ? 'Mapa de Calor — Entregas' : 'Mapa Desbravado',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            isDelivery
                ? 'Pontos quentes mostram onde você mais atende entregas.'
                : 'Quanto mais brilhante a área, mais você explorou. As áreas escuras ainda não foram desbravadas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._buildRegionTiles(data, theme),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            'Histórico de Rotas',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...data.history.map((e) => _buildHistoryTile(e, theme)),
      ],
    );
  }

  Widget _buildSummaryHeader(RoutesData data, ThemeData theme) {
    final formatter = NumberFormat('#,##0.0');
    final hours = data.totalDuration.inMinutes / 60;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.racingOrange.withOpacity(0.18),
              AppColors.racingOrangeDark.withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.racingOrange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _summaryStat(
                theme,
                icon: LucideIcons.navigation,
                label: 'Rotas',
                value: data.history.length.toString(),
              ),
            ),
            _vDivider(theme),
            Expanded(
              child: _summaryStat(
                theme,
                icon: LucideIcons.mapPin,
                label: 'Distância',
                value: '${formatter.format(data.totalDistanceKm)} km',
              ),
            ),
            _vDivider(theme),
            Expanded(
              child: _summaryStat(
                theme,
                icon: LucideIcons.clock,
                label: 'Tempo',
                value: '${formatter.format(hours)} h',
              ),
            ),
            _vDivider(theme),
            Expanded(
              child: _summaryStat(
                theme,
                icon: data.profileIsDelivery
                    ? LucideIcons.flame
                    : LucideIcons.compass,
                label: data.profileIsDelivery ? 'Calor' : 'Explorado',
                value:
                    '${(data.overallExploredFraction * 100).round()}%',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.dividerColor.withOpacity(0.5),
    );
  }

  Widget _summaryStat(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.racingOrange, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildMap(RoutesData data, ThemeData theme) {
    final center = LatLng(data.centerLatitude, data.centerLongitude);
    final isDelivery = data.profileIsDelivery;
    final isDark = theme.brightness == Brightness.dark;
    final showFog = !isDelivery;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.racingOrange.withOpacity(0.25),
            ),
          ),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: isDelivery ? 13 : 11,
                  minZoom: 9,
                  maxZoom: 17,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.girocerto.app',
                    tileBuilder: (context, child, _) => isDark
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              -0.9, 0, 0, 0, 255,
                              0, -0.9, 0, 0, 255,
                              0, 0, -0.9, 0, 255,
                              0, 0, 0, 1, 0,
                            ]),
                            child: child,
                          )
                        : child,
                  ),
                  CircleLayer(
                    circles: _buildHeatCircles(data, isDelivery),
                  ),
                  if (_selectedEntry != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _selectedEntry!.path
                              .map((p) => LatLng(p.latitude, p.longitude))
                              .toList(),
                          color: AppColors.racingOrange,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                ],
              ),
              if (showFog)
                IgnorePointer(
                  child: StreamBuilder(
                    stream: _mapController.mapEventStream,
                    builder: (context, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _FogOfWarPainter(
                        explored: data.heatmapPoints,
                        mapCenter: center,
                        mapController: _mapController,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  children: [
                    _mapButton(
                      icon: LucideIcons.plus,
                      onTap: () {
                        final z = _mapController.camera.zoom + 1;
                        _mapController.move(
                            _mapController.camera.center, z);
                      },
                    ),
                    const SizedBox(height: 6),
                    _mapButton(
                      icon: LucideIcons.minus,
                      onTap: () {
                        final z = _mapController.camera.zoom - 1;
                        _mapController.move(
                            _mapController.camera.center, z);
                      },
                    ),
                    const SizedBox(height: 6),
                    _mapButton(
                      icon: LucideIcons.locateFixed,
                      onTap: () {
                        setState(() => _selectedEntry = null);
                        _mapController.move(
                            center, isDelivery ? 13 : 11);
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDelivery
                            ? LucideIcons.flame
                            : LucideIcons.compass,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDelivery ? 'Heatmap entregas' : 'Mapa desbravado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  List<CircleMarker> _buildHeatCircles(RoutesData data, bool isDelivery) {
    return data.heatmapPoints.map((p) {
      final base = isDelivery
          ? _heatColor(p.intensity)
          : _exploredColor(p.intensity);
      return CircleMarker(
        point: LatLng(p.latitude, p.longitude),
        radius: isDelivery ? (12 + p.intensity * 22) : (16 + p.intensity * 22),
        color: base.withOpacity(isDelivery ? 0.45 : 0.55),
        borderStrokeWidth: 0,
        useRadiusInMeter: false,
      );
    }).toList();
  }

  Color _heatColor(double intensity) {
    if (intensity > 0.8) return AppColors.statusCritical;
    if (intensity > 0.55) return AppColors.statusWarning;
    return AppColors.statusOk;
  }

  Color _exploredColor(double intensity) {
    return Color.lerp(
        AppColors.racingOrange.withOpacity(0.6),
        AppColors.racingOrangeLight,
        intensity)!;
  }

  List<Widget> _buildRegionTiles(RoutesData data, ThemeData theme) {
    return [
      SizedBox(
        height: 96,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, i) {
            final region = data.regions[i];
            return GestureDetector(
              onTap: () {
                _mapController.move(
                  LatLng(region.latitude, region.longitude),
                  14,
                );
              },
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          data.profileIsDelivery
                              ? LucideIcons.flame
                              : LucideIcons.mapPin,
                          color: AppColors.racingOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            region.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: region.exploredFraction,
                        minHeight: 6,
                        backgroundColor: AppColors.racingOrange
                            .withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.racingOrange),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.profileIsDelivery
                          ? '${region.visitCount} entregas'
                          : '${(region.exploredFraction * 100).round()}% desbravado',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: data.regions.length,
        ),
      ),
    ];
  }

  Widget _buildHistoryTile(RouteHistoryEntry e, ThemeData theme) {
    final selected = _selectedEntry?.id == e.id;
    final fmt = DateFormat('dd/MM HH:mm', 'pt_BR');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Material(
        color: selected
            ? AppColors.racingOrange.withOpacity(0.10)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() => _selectedEntry = selected ? null : e);
            if (!selected && e.path.isNotEmpty) {
              final first = e.path.first;
              _mapController.move(
                LatLng(first.latitude, first.longitude),
                14,
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.racingOrange.withOpacity(0.4)
                    : theme.dividerColor.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.racingOrange.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    e.category == RouteCategory.delivery
                        ? LucideIcons.package
                        : e.category == RouteCategory.trip
                            ? LucideIcons.map
                            : e.category == RouteCategory.commute
                                ? LucideIcons.briefcase
                                : LucideIcons.navigation,
                    color: AppColors.racingOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.originLabel ?? "Origem"} → ${e.destinationLabel ?? "Destino"}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${fmt.format(e.startedAt)} • ${e.distanceKm.toStringAsFixed(1)} km • ${e.duration.inMinutes} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronRight,
                  color:
                      theme.iconTheme.color?.withOpacity(0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter que escurece o mapa todo (fog-of-war) e "perfura" as áreas que
/// o usuário já explorou — usado para pilotos lazer/diário.
class _FogOfWarPainter extends CustomPainter {
  final List<RoutePoint> explored;
  final LatLng mapCenter;
  final MapController mapController;
  final bool isDark;

  _FogOfWarPainter({
    required this.explored,
    required this.mapCenter,
    required this.mapController,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fogColor = isDark
        ? const Color(0xFF000000).withOpacity(0.55)
        : const Color(0xFF1A1A1A).withOpacity(0.40);

    final paint = Paint()..color = fogColor;
    final layer = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(layer, Paint());
    canvas.drawRect(layer, paint);

    final clearPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final camera = mapController.camera;
    for (final point in explored) {
      final pt = camera.latLngToScreenPoint(
        LatLng(point.latitude, point.longitude),
      );
      final radius = 28 + point.intensity * 24;
      canvas.drawCircle(
        Offset(pt.x, pt.y),
        radius,
        clearPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FogOfWarPainter oldDelegate) =>
      oldDelegate.explored != explored ||
      oldDelegate.mapCenter != mapCenter ||
      oldDelegate.isDark != isDark;
}
