import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_order.dart';
import '../../utils/colors.dart';
import 'delivery_trip_controller.dart';
import 'trip_mapbox_navigation_host.dart';
import 'trip_navigation_experiment.dart';

/// Modo Corrida dedicado (experimento Fase 1): apenas Mapbox + HUD Giro Certo.
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

  @override
  void initState() {
    super.initState();
    TripNavigationExperiment.activeSessionOpen = true;
    _controller = DeliveryTripController(initialOrder: widget.initialOrder);
    _controller.startLocationTracking();
  }

  @override
  void dispose() {
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
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DeliveryTripController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<DeliveryTripController>(
          builder: (context, trip, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                TripMapboxNavigationHost(
                  key: _mapHostKey,
                  controller: trip,
                ),
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
                    child: _TripStageActions(
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

class _TripStageActions extends StatelessWidget {
  const _TripStageActions({
    required this.trip,
    required this.onArrivedAtStore,
    required this.onCollectAndStart,
    required this.onCompleteDelivery,
  });

  final DeliveryTripController trip;
  final Future<void> Function() onArrivedAtStore;
  final Future<void> Function() onCollectAndStart;
  final Future<void> Function() onCompleteDelivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final order = trip.order;
    final loading = trip.isLoading;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppColors.panelDarkHigh.withValues(alpha: 0.96)
                : AppColors.panelLightHigh.withValues(alpha: 0.98),
            isDark
                ? AppColors.panelDarkLow.withValues(alpha: 0.93)
                : AppColors.panelLightLow.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.racingOrange.withValues(alpha: 0.28)),
        boxShadow: AppColors.raisedPanelShadows(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trip.stageTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trip.phase == DeliveryTripPhase.headingToClient
                ? order.deliveryAddress
                : order.storeAddress,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (trip.phase == DeliveryTripPhase.headingToStore) ...[
            const SizedBox(height: 10),
            _primaryButton(
              label: loading ? 'Atualizando...' : 'Cheguei no estabelecimento',
              icon: LucideIcons.flag,
              color: AppColors.racingOrangeDark,
              loading: loading,
              onPressed: loading ? null : onArrivedAtStore,
            ),
          ],
          if (trip.phase == DeliveryTripPhase.waitingAtStore) ...[
            const SizedBox(height: 10),
            _primaryButton(
              label: loading ? 'Atualizando...' : 'Coletar e iniciar entrega',
              icon: LucideIcons.package,
              color: AppColors.neonGreen,
              loading: loading,
              onPressed: loading ? null : onCollectAndStart,
            ),
          ],
          if (trip.phase == DeliveryTripPhase.headingToClient) ...[
            const SizedBox(height: 10),
            _primaryButton(
              label: loading ? 'Finalizando...' : 'Finalizar entrega',
              icon: LucideIcons.checkCircle,
              color: AppColors.neonGreen,
              loading: loading,
              onPressed: loading ? null : onCompleteDelivery,
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool loading,
    required Future<void> Function()? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed == null
            ? null
            : () async {
                await onPressed();
              },
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
      ),
    );
  }
}
