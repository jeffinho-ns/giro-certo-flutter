import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

import 'delivery_trip_controller.dart';

/// Mapbox em tela cheia para o experimento: uma única platform view por sessão.
/// Ao mudar o destino (loja → cliente), recalcula a rota sem remontar o widget.
class TripMapboxNavigationHost extends StatefulWidget {
  const TripMapboxNavigationHost({
    super.key,
    required this.controller,
  });

  final DeliveryTripController controller;

  @override
  State<TripMapboxNavigationHost> createState() =>
      TripMapboxNavigationHostState();
}

class TripMapboxNavigationHostState extends State<TripMapboxNavigationHost> {
  MapBoxNavigationViewController? _mapController;
  late MapBoxOptions _options;
  bool _starting = false;
  bool _buildingRoute = false;
  String? _banner;
  double? _distanceRemainingM;
  double? _durationRemainingS;
  String? _error;
  double? _lastRoutedDestLat;
  double? _lastRoutedDestLng;
  bool _lastGuidanceActive = false;

  DeliveryTripController get _trip => widget.controller;

  @override
  void initState() {
    super.initState();
    _options = MapBoxNavigation.instance.getDefaultOptions();
    _options.language = 'pt-BR';
    _options.units = VoiceUnits.metric;
    _options.mode = MapBoxNavigationMode.drivingWithTraffic;
    _options.voiceInstructionsEnabled = true;
    _options.bannerInstructionsEnabled = false;
    _options.simulateRoute = false;
    _options.longPressDestinationEnabled = false;
    _options.tilt = 50;
    _options.zoom = 17;
    _options.bearing = 0;
    _options.enableRefresh = true;
    _options.alternatives = true;
    _options.animateBuildRoute = true;
    _applyInitialCamera();
    MapBoxNavigation.instance.setDefaultOptions(_options);
    _trip.addListener(_onTripChanged);
  }

  Future<void> recenterNavigation() async {
    final controller = _mapController ?? _trip.mapboxController;
    if (controller == null) return;
    await controller.recenter();
  }

  @override
  void dispose() {
    _trip.removeListener(_onTripChanged);
    unawaited(_mapController?.finishNavigation());
    _mapController?.dispose();
    super.dispose();
  }

  void _applyInitialCamera() {
    final lat = _trip.latitude;
    final lng = _trip.longitude;
    if (lat != null && lng != null) {
      _options.initialLatitude = lat;
      _options.initialLongitude = lng;
    }
  }

  void _onTripChanged() {
    if (!mounted) return;
    _applyInitialCamera();
    if (_trip.navigationGuidanceActive) {
      if (_mapController != null &&
          _lastRoutedDestLat == null &&
          _trip.latitude != null &&
          _trip.longitude != null) {
        unawaited(_startRouteBuild());
      } else {
        _maybeRebuildRouteForDestination();
      }
    }
    setState(() {});
  }

  bool _sameDestination(double lat, double lng) {
    return _lastRoutedDestLat != null &&
        _lastRoutedDestLng != null &&
        (_lastRoutedDestLat! - lat).abs() < 0.00001 &&
        (_lastRoutedDestLng! - lng).abs() < 0.00001;
  }

  Future<void> _maybeRebuildRouteForDestination() async {
    final lat = _trip.destinationLatitude;
    final lng = _trip.destinationLongitude;
    if (_sameDestination(lat, lng) && _lastGuidanceActive) return;
    await _startRouteBuild();
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
            _buildingRoute = false;
            _lastRoutedDestLat = _trip.destinationLatitude;
            _lastRoutedDestLng = _trip.destinationLongitude;
            _lastGuidanceActive = _trip.navigationGuidanceActive;
          });
        }
        if (!_starting && _mapController != null && _trip.navigationGuidanceActive) {
          _starting = true;
          try {
            await _mapController!.startNavigation(options: _options);
          } catch (e, st) {
            debugPrint('TripMapbox startNavigation: $e\n$st');
            if (mounted) {
              setState(() {
                _starting = false;
                _error =
                    'Navegacao nativa nao arrancou. Verifique o token Mapbox.';
              });
            }
          }
        }
        break;
      case MapBoxEvent.route_build_failed:
        if (mounted) {
          setState(() {
            _buildingRoute = false;
            _error =
                'Nao foi possivel calcular a rota. Verifique o token e a ligacao.';
          });
        }
        break;
      case MapBoxEvent.navigation_running:
        if (mounted) setState(() => _starting = false);
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        if (mounted) setState(() => _starting = false);
        break;
      default:
        break;
    }
  }

  List<WayPoint> _wayPoints() {
    final lat = _trip.latitude ?? _options.initialLatitude ?? 0;
    final lng = _trip.longitude ?? _options.initialLongitude ?? 0;
    return [
      WayPoint(
        name: 'Origem',
        latitude: lat,
        longitude: lng,
        isSilent: true,
      ),
      WayPoint(
        name: _trip.destinationLabel,
        latitude: _trip.destinationLatitude,
        longitude: _trip.destinationLongitude,
        isSilent: false,
      ),
    ];
  }

  Future<void> _startRouteBuild() async {
    if (!_trip.navigationGuidanceActive) return;
    final c = _mapController;
    if (c == null) return;
    setState(() {
      _error = null;
      _starting = false;
      _buildingRoute = true;
    });
    await c.clearRoute();
    final ok = await c.buildRoute(wayPoints: _wayPoints(), options: _options);
    if (!ok && mounted) {
      setState(() {
        _error = 'Falha ao pedir rota ao Mapbox.';
        _buildingRoute = false;
      });
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
    final waiting = _trip.phase == DeliveryTripPhase.waitingAtStore;
    final statusLabel = waiting
        ? 'No estabelecimento · aguardando retirada'
        : _buildingRoute
            ? 'Calculando a melhor rota...'
            : 'Navegacao ativa · trafego em tempo real';
    final topInset = MediaQuery.of(context).padding.top;
    const nativeControlsWidth = 80.0;
    const nativeControlsHeight = 56.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        MapBoxNavigationView(
          options: _options,
          onRouteEvent: _onEmbeddedRouteEvent,
          onCreated: (controller) async {
            _mapController = controller;
            _trip.mapboxController = controller;
            await Future<void>.delayed(const Duration(milliseconds: 120));
            if (!mounted) return;
            if (_trip.navigationGuidanceActive) {
              await _startRouteBuild();
            }
          },
        ),
        if (waiting)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: topInset + nativeControlsHeight,
          left: 12,
          right: 12 + nativeControlsWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TripHudCard(
                stageLabel: _trip.stageTitle,
                destination: _trip.destinationLabel,
                instruction: waiting
                    ? 'Confirme a retirada quando o pedido estiver pronto'
                    : (_banner?.isNotEmpty == true
                        ? _banner!
                        : 'Siga a rota no mapa'),
                distanceLabel: _formatDistance(_distanceRemainingM),
                etaLabel: _formatDuration(_durationRemainingS),
                statusLabel: statusLabel,
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
              if (_buildingRoute && _error == null && !waiting)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripHudCard extends StatelessWidget {
  const _TripHudCard({
    required this.stageLabel,
    required this.destination,
    required this.instruction,
    required this.distanceLabel,
    required this.etaLabel,
    required this.statusLabel,
  });

  final String stageLabel;
  final String destination;
  final String instruction;
  final String distanceLabel;
  final String etaLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: const Color(0xFF1E1E1E).withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF6B3D).withValues(alpha: 0.35),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stageLabel,
              style: const TextStyle(
                color: Color(0xFFFF8A65),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              destination,
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
              instruction,
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
                _HudMetric(label: 'Restante', value: distanceLabel),
                const SizedBox(width: 16),
                _HudMetric(label: 'ETA', value: etaLabel),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              statusLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
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
