import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:provider/provider.dart';

import '../models/delivery_order.dart';
import '../providers/theme_provider.dart';
import '../utils/giro_mapbox_navigation_theme.dart';

/// Mapa Mapbox embutido na home: rota + navegação ativa (estilo app de navegação).
class HomeEmbeddedMapboxNavigation extends StatefulWidget {
  const HomeEmbeddedMapboxNavigation({
    super.key,
    required this.order,
    required this.originLatitude,
    required this.originLongitude,
    this.onControllerReady,
    this.onNavigationFailed,
    this.onNavigationRunning,
  });

  final DeliveryOrder order;
  final double originLatitude;
  final double originLongitude;
  final ValueChanged<MapBoxNavigationViewController>? onControllerReady;
  final VoidCallback? onNavigationFailed;
  final VoidCallback? onNavigationRunning;

  @override
  HomeEmbeddedMapboxNavigationState createState() =>
      HomeEmbeddedMapboxNavigationState();
}

class HomeEmbeddedMapboxNavigationState
    extends State<HomeEmbeddedMapboxNavigation> {
  MapBoxNavigationViewController? _controller;
  late MapBoxOptions _options;
  String? _banner;
  bool _routeBuilt = false;
  bool _navigating = false;
  bool _starting = false;
  bool _buildingRoute = false;
  String? _error;
  double? _distanceRemainingM;
  double? _durationRemainingS;
  ThemeProvider? _themeProvider;
  bool? _lastIsDark;

  bool get _headingToStore => widget.order.status == DeliveryStatus.accepted;

  double get _destinationLatitude => _headingToStore
      ? widget.order.storeLatitude
      : widget.order.deliveryLatitude;

  double get _destinationLongitude => _headingToStore
      ? widget.order.storeLongitude
      : widget.order.deliveryLongitude;

  String get _destinationLabel =>
      _headingToStore ? widget.order.storeName : widget.order.deliveryAddress;

  @override
  void initState() {
    super.initState();
    _options = MapBoxNavigation.instance.getDefaultOptions();
    _options.language = 'pt-BR';
    _options.units = VoiceUnits.metric;
    _options.mode = MapBoxNavigationMode.drivingWithTraffic;
    _options.voiceInstructionsEnabled = true;
    _options.bannerInstructionsEnabled = true;
    _options.simulateRoute = false;
    _options.longPressDestinationEnabled = false;
    _options.bearing = 0;
    _options.enableRefresh = true;
    _options.alternatives = true;
    _options.initialLatitude = widget.originLatitude;
    _options.initialLongitude = widget.originLongitude;
    _options.animateBuildRoute = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (_themeProvider != themeProvider) {
      _themeProvider?.removeListener(_onAppThemeChanged);
      _themeProvider = themeProvider;
      _themeProvider?.addListener(_onAppThemeChanged);
    }
    _syncMapAppearance();
  }

  void _onAppThemeChanged() {
    if (!mounted) return;
    _syncMapAppearance();
  }

  void _syncMapAppearance() {
    final isDark = _themeProvider?.isDarkMode ??
        Theme.of(context).brightness == Brightness.dark;
    if (_lastIsDark == isDark) return;
    _lastIsDark = isDark;
    GiroMapboxNavigationTheme.apply(_options, isDarkMode: isDark);
    MapBoxNavigation.instance.setDefaultOptions(_options);
  }

  @override
  void dispose() {
    _themeProvider?.removeListener(_onAppThemeChanged);
    unawaited(_controller?.finishNavigation());
    _controller?.dispose();
    super.dispose();
  }

  Future<void> recenterNavigation() async {
    await _controller?.recenter();
  }

  Future<void> _onEmbeddedRouteEvent(RouteEvent e) async {
    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        final data = e.data;
        if (data is RouteProgressEvent) {
          final instr = data.currentStepInstruction;
          final dist = data.distance;
          final dur = data.duration;
          if (!mounted) return;
          setState(() {
            if (instr != null && instr.isNotEmpty) _banner = instr;
            if (dist != null && dist.isFinite) _distanceRemainingM = dist;
            if (dur != null && dur.isFinite) _durationRemainingS = dur;
          });
        }
        break;
      case MapBoxEvent.route_building:
        if (mounted) {
          setState(() {
            _buildingRoute = true;
            _error = null;
          });
        }
        break;
      case MapBoxEvent.route_built:
        if (mounted) {
          setState(() {
            _routeBuilt = true;
            _buildingRoute = false;
          });
        }
        if (!_starting && _controller != null) {
          _starting = true;
          try {
            await _controller!.startNavigation(options: _options);
          } catch (e, st) {
            debugPrint('Mapbox startNavigation: $e\n$st');
            if (mounted) {
              setState(() {
                _starting = false;
                _error =
                    'Navegacao nativa nao arrancou. Verifique token Mapbox e tente outra vez.';
              });
              widget.onNavigationFailed?.call();
            }
          }
        }
        break;
      case MapBoxEvent.route_build_failed:
        if (mounted) {
          const msg =
              'Nao foi possivel calcular a rota no Mapbox. Verifique o token e a ligacao.';
          setState(() {
            _routeBuilt = false;
            _buildingRoute = false;
            _error = msg;
          });
          widget.onNavigationFailed?.call();
        }
        break;
      case MapBoxEvent.navigation_running:
        if (mounted) {
          setState(() => _navigating = true);
          widget.onNavigationRunning?.call();
        }
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        if (mounted) {
          setState(() {
            _routeBuilt = false;
            _navigating = false;
          });
        }
        break;
      default:
        break;
    }
  }

  List<WayPoint> get _wayPoints {
    final origin = WayPoint(
      name: 'Origem',
      latitude: widget.originLatitude,
      longitude: widget.originLongitude,
      isSilent: true,
    );
    final dest = WayPoint(
      name: _destinationLabel,
      latitude: _destinationLatitude,
      longitude: _destinationLongitude,
      isSilent: false,
    );
    return [origin, dest];
  }

  Future<void> _startRouteBuild() async {
    setState(() {
      _error = null;
      _starting = false;
      _buildingRoute = true;
    });
    final c = _controller;
    if (c == null) return;
    await c.clearRoute();
    final ok = await c.buildRoute(wayPoints: _wayPoints, options: _options);
    if (!ok && mounted) {
      const msg = 'Falha ao pedir rota ao Mapbox.';
      setState(() {
        _error = msg;
        _buildingRoute = false;
      });
      widget.onNavigationFailed?.call();
    }
  }

  String _formatDistance(double? meters) {
    if (meters == null || !meters.isFinite || meters < 1) return '--';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(double? seconds) {
    if (seconds == null || !seconds.isFinite || seconds < 1) return '--';
    final totalMin = (seconds / 60).round();
    if (totalMin < 60) return '$totalMin min';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final stageLabel =
        _headingToStore ? 'Para o estabelecimento' : 'Para o cliente';
    final statusLabel = _navigating
        ? 'Navegacao ativa · trafego em tempo real'
        : _buildingRoute
            ? 'Calculando a melhor rota...'
            : 'Preparando navegacao...';

    return Stack(
      fit: StackFit.expand,
      children: [
        MapBoxNavigationView(
          options: _options,
          onRouteEvent: _onEmbeddedRouteEvent,
          onCreated: (controller) async {
            _controller = controller;
            widget.onControllerReady?.call(controller);
            await Future<void>.delayed(const Duration(milliseconds: 120));
            if (!mounted) return;
            await _startRouteBuild();
          },
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 52, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 4,
                  color: const Color(0xFF0D47A1),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stageLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _destinationLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _banner?.isNotEmpty == true
                              ? _banner!
                              : 'Siga a rota no mapa',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _HudMetric(
                              label: 'Restante',
                              value: _formatDistance(_distanceRemainingM),
                            ),
                            const SizedBox(width: 16),
                            _HudMetric(
                              label: 'ETA',
                              value: _formatDuration(_durationRemainingS),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Material(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                if (_buildingRoute && _error == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
