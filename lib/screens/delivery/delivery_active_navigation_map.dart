import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

import '../../models/delivery_order.dart';

/// Navegação turn-by-turn in-app (Mapbox Navigation SDK).
///
/// Requer:
/// - Android: `MAPBOX_DOWNLOADS_TOKEN` (Gradle) + string `mapbox_access_token` (ver `android/app/build.gradle.kts`).
/// - iOS: chave `MBXAccessToken` no `Info.plist` (token público pk.).
/// - Conta Mapbox com Directions + Navigation habilitados.
class DeliveryActiveNavigationMap extends StatefulWidget {
  const DeliveryActiveNavigationMap({
    super.key,
    required this.order,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationLabel,
  });

  final DeliveryOrder order;
  final double originLatitude;
  final double originLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String destinationLabel;

  static Future<void> open(
    BuildContext context, {
    required DeliveryOrder order,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationLabel,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => DeliveryActiveNavigationMap(
          order: order,
          originLatitude: originLatitude,
          originLongitude: originLongitude,
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
          destinationLabel: destinationLabel,
        ),
      ),
    );
  }

  @override
  State<DeliveryActiveNavigationMap> createState() =>
      _DeliveryActiveNavigationMapState();
}

class _DeliveryActiveNavigationMapState extends State<DeliveryActiveNavigationMap> {
  MapBoxNavigationViewController? _controller;
  late MapBoxOptions _options;
  String? _banner;
  bool _routeBuilt = false;
  bool _navigating = false;
  bool _starting = false;
  String? _error;

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
    _options.tilt = 45;
    _options.zoom = 16;
    _options.bearing = 0;
    _options.enableRefresh = true;
    _options.alternatives = false;
    _options.initialLatitude = widget.originLatitude;
    _options.initialLongitude = widget.originLongitude;
    _options.animateBuildRoute = true;
    MapBoxNavigation.instance.setDefaultOptions(_options);
  }

  @override
  void dispose() {
    unawaited(_controller?.finishNavigation());
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onEmbeddedRouteEvent(RouteEvent e) async {
    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        final data = e.data;
        if (data is RouteProgressEvent) {
          final instr = data.currentStepInstruction;
          if (instr != null && instr.isNotEmpty && mounted) {
            setState(() => _banner = instr);
          }
        }
        break;
      case MapBoxEvent.route_built:
        if (mounted) setState(() => _routeBuilt = true);
        if (!_starting && _controller != null) {
          _starting = true;
          await _controller!.startNavigation(options: _options);
        }
        break;
      case MapBoxEvent.route_build_failed:
        if (mounted) {
          setState(() {
            _routeBuilt = false;
            _error =
                'Nao foi possivel calcular a rota no Mapbox. Verifique o token e a ligacao.';
          });
        }
        break;
      case MapBoxEvent.navigation_running:
        if (mounted) setState(() => _navigating = true);
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

  Future<void> _close() async {
    await _controller?.finishNavigation();
    if (mounted) Navigator.of(context).pop();
  }

  List<WayPoint> get _wayPoints {
    final origin = WayPoint(
      name: 'Origem',
      latitude: widget.originLatitude,
      longitude: widget.originLongitude,
      isSilent: true,
    );
    final dest = WayPoint(
      name: widget.destinationLabel,
      latitude: widget.destinationLatitude,
      longitude: widget.destinationLongitude,
      isSilent: false,
    );
    return [origin, dest];
  }

  Future<void> _startRouteBuild() async {
    setState(() {
      _error = null;
      _starting = false;
    });
    final c = _controller;
    if (c == null) return;
    await c.clearRoute();
    final ok = await c.buildRoute(wayPoints: _wayPoints, options: _options);
    if (!ok && mounted) {
      setState(() => _error = 'Falha ao pedir rota ao Mapbox.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.order.status == DeliveryStatus.inTransit ||
            widget.order.status == DeliveryStatus.inProgress
        ? 'Cliente'
        : 'Estabelecimento';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _close();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            MapBoxNavigationView(
              options: _options,
              onRouteEvent: _onEmbeddedRouteEvent,
              onCreated: (controller) async {
                _controller = controller;
                await controller.initialize();
                await _startRouteBuild();
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: _close,
                          icon: const Icon(Icons.close),
                          tooltip: 'Fechar navegação',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Text(
                                'Navegação → $stage',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_banner != null && _banner!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Material(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _banner!,
                              style: const TextStyle(color: Colors.white),
                            ),
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
                    if (!_routeBuilt && _error == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    const Spacer(),
                    if (_routeBuilt && !_navigating)
                      FilledButton.icon(
                        onPressed: _startRouteBuild,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recalcular rota'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
