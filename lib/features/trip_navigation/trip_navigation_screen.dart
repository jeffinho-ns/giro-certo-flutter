import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_order.dart';
import '../../providers/theme_provider.dart';
import '../../services/realtime_service.dart';
import '../../utils/colors.dart';
import '../../utils/delivery_geofence.dart';
import 'delivery_trip_controller.dart';
import 'trip_mapbox_navigation_host.dart';
import 'trip_navigation_experiment.dart';
import 'trip_navigation_immersive_scope.dart';
import 'trip_navigation_performance.dart';
import 'widgets/trip_navigation_perf_overlay.dart';
import 'widgets/trip_delivery_proof_panel.dart';
import 'widgets/trip_pickup_code_sheet.dart';
import 'widgets/trip_stage_action_sheet.dart';

/// Modo Corrida dedicado: Mapbox em tela cheia + HUD e acoes do Giro Certo.
class TripNavigationScreen extends StatefulWidget {
  const TripNavigationScreen({
    super.key,
    required this.initialOrder,
  });

  final DeliveryOrder initialOrder;

  @override
  State<TripNavigationScreen> createState() => _TripNavigationScreenState();
}

class _TripNavigationScreenState extends State<TripNavigationScreen> {
  final GlobalKey<TripMapboxNavigationHostState> _mapHostKey =
      GlobalKey<TripMapboxNavigationHostState>();
  late final DeliveryTripController _controller;
  final TripNavigationPerformance _performance = TripNavigationPerformance();
  TimingsCallback? _frameTimingsCallback;

  @override
  void initState() {
    super.initState();
    TripNavigationExperiment.activeSessionOpen = true;
    _controller = DeliveryTripController(initialOrder: widget.initialOrder);
    _controller.startLocationTracking();
    _frameTimingsCallback = (List<FrameTiming> timings) {
      for (final timing in timings) {
        _performance.recordSlowFrame(
          timing.totalSpan.inMicroseconds / 1000,
        );
      }
    };
    SchedulerBinding.instance.addTimingsCallback(_frameTimingsCallback!);
  }

  @override
  void dispose() {
    if (_frameTimingsCallback != null) {
      SchedulerBinding.instance.removeTimingsCallback(_frameTimingsCallback!);
    }
    _performance.logSummary(orderId: _controller.order.id);
    TripNavigationExperiment.activeSessionOpen = false;
    RealtimeService.instance.setNavigationMode(false);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onCollectAndStart() async {
    final code = await showTripPickupCodeSheet(context);
    if (code == null || code.isEmpty) return;
    final ok = await _controller.collectAndStartDelivery(code);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ??
              'Nao foi possivel validar o codigo de retirada.',
        ),
      ),
    );
  }

  Future<void> _onConfirmArrivalAtStore() async {
    final result = await _controller.confirmArrivalAtStore();
    if (!mounted) return;
    if (result == ConfirmArrivalResult.tooFarFromStore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você precisa estar mais perto da loja para confirmar a chegada',
          ),
        ),
      );
      return;
    }
    if (result == ConfirmArrivalResult.locationUnavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel obter sua localizacao. Tente novamente.',
          ),
        ),
      );
    }
  }

  Future<void> _onArrivedAtDestination() async {
    final ok = await _controller.confirmArrivalAtDestination();
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ??
              'Nao foi possivel confirmar a chegada ao cliente.',
        ),
      ),
    );
  }

  Future<void> _onCompleteDelivery(String pin) async {
    final ok = await _controller.completeDelivery(pin);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrega finalizada.')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return TripNavigationImmersiveScope(
      child: ChangeNotifierProvider<DeliveryTripController>.value(
        value: _controller,
        child: Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: context.watch<ThemeProvider>().isDarkMode
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          body: Consumer<DeliveryTripController>(
            builder: (context, trip, _) {
              final showProofPanel =
                  trip.phase == DeliveryTripPhase.awaitingDeliveryProof;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (!showProofPanel)
                    TripMapboxNavigationHost(
                      key: _mapHostKey,
                      controller: trip,
                      performance: _performance,
                    ),
                  if (showProofPanel)
                    TripDeliveryProofPanel(
                      order: trip.order,
                      isLoading: trip.isLoading,
                      errorMessage: trip.errorMessage,
                      onSubmit: _onCompleteDelivery,
                    ),
                  if (!showProofPanel) ...[
                    TripNavigationPerfOverlay(performance: _performance),
                    Positioned(
                      right: 16,
                      bottom: 188,
                      child: SafeArea(
                        top: false,
                        child: _RecenterFab(
                          onPressed: () {
                            unawaited(
                              _mapHostKey.currentState?.recenterNavigation(),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: SafeArea(
                        top: false,
                        child: TripStageActionSheet(
                          trip: trip,
                          onArrivedAtStore: _onConfirmArrivalAtStore,
                          onCollectAndStart: _onCollectAndStart,
                          onArrivedAtDestination: _onArrivedAtDestination,
                        ),
                      ),
                    ),
                  ],
                  if (!showProofPanel && trip.errorMessage != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 8,
                      child: Material(
                        color: AppColors.alertRed,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            trip.errorMessage!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecenterFab extends StatelessWidget {
  const _RecenterFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.racingOrange.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            LucideIcons.crosshair,
            color: AppColors.neonGreen,
            size: 22,
          ),
        ),
      ),
    );
  }
}
