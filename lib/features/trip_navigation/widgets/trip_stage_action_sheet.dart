import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../utils/colors.dart';
import '../delivery_trip_controller.dart';

class TripStageActionSheet extends StatelessWidget {
  const TripStageActionSheet({
    super.key,
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey<DeliveryTripPhase>(trip.phase),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _actionHint(trip.phase),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trip.phase == DeliveryTripPhase.headingToClient
                  ? order.deliveryAddress
                  : order.storeAddress,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            if (trip.phase == DeliveryTripPhase.headingToStore)
              _primaryButton(
                label: loading ? 'Atualizando...' : 'Cheguei no estabelecimento',
                icon: LucideIcons.flag,
                color: AppColors.racingOrangeDark,
                loading: loading,
                onPressed: loading ? null : onArrivedAtStore,
              ),
            if (trip.phase == DeliveryTripPhase.waitingAtStore)
              _primaryButton(
                label: loading ? 'Atualizando...' : 'Coletar e iniciar entrega',
                icon: LucideIcons.package,
                color: AppColors.neonGreen,
                loading: loading,
                onPressed: loading ? null : onCollectAndStart,
              ),
            if (trip.phase == DeliveryTripPhase.headingToClient)
              _primaryButton(
                label: loading ? 'Finalizando...' : 'Finalizar entrega',
                icon: LucideIcons.checkCircle,
                color: AppColors.neonGreen,
                loading: loading,
                onPressed: loading ? null : onCompleteDelivery,
              ),
          ],
        ),
      ),
    );
  }

  String _actionHint(DeliveryTripPhase phase) {
    switch (phase) {
      case DeliveryTripPhase.headingToStore:
        return 'Confirme quando estiver no local de retirada.';
      case DeliveryTripPhase.waitingAtStore:
        return 'Pedido pronto? Informe o codigo e siga para o cliente.';
      case DeliveryTripPhase.headingToClient:
        return 'Finalize quando a entrega for concluida.';
    }
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
