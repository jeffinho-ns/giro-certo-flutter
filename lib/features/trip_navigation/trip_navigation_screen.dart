import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_order.dart';
import '../../providers/theme_provider.dart';
import '../../utils/colors.dart';
import 'delivery_trip_controller.dart';
import 'trip_mapbox_navigation_host.dart';
import 'trip_navigation_experiment.dart';
import 'trip_navigation_immersive_scope.dart';
import 'trip_navigation_performance.dart';
import 'widgets/trip_navigation_perf_overlay.dart';
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
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _promptPickupCode(DeliveryOrder order) async {
    final controller = TextEditingController();
    final expected = (order.internalCode ?? '').trim();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar retirada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expected.isNotEmpty)
                Text(
                  'Código da loja: $expected',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 8),
              const Text('Digite o código interno para iniciar a entrega.'),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'GC-XXXXXXXX',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pop(controller.text.trim().toUpperCase()),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onCollectAndStart() async {
    final code = await _promptPickupCode(_controller.order);
    if (code == null || code.isEmpty) return;
    await _controller.collectAndStartDelivery(code);
  }

  Future<void> _onComplete() async {
    final ok = await _controller.completeDelivery();
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
              return Stack(
                fit: StackFit.expand,
                children: [
                  TripMapboxNavigationHost(
                    key: _mapHostKey,
                    controller: trip,
                    performance: _performance,
                  ),
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
                        onArrivedAtStore: trip.confirmArrivalAtStore,
                        onCollectAndStart: _onCollectAndStart,
                        onCompleteDelivery: _onComplete,
                      ),
                    ),
                  ),
                  if (trip.errorMessage != null)
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
