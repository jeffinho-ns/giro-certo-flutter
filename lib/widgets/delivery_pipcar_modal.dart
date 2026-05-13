import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/delivery_order.dart';
import '../utils/colors.dart';

/// Oferta imersiva de corrida com contagem regressiva.
class DeliveryPipcarModal extends StatefulWidget {
  const DeliveryPipcarModal({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    this.countdownSeconds = 15,
    this.distanceToStoreKm,
    this.routeDistanceKm,
  });

  final DeliveryOrder order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final int countdownSeconds;
  final double? distanceToStoreKm;
  final double? routeDistanceKm;

  @override
  State<DeliveryPipcarModal> createState() => _DeliveryPipcarModalState();
}

class _DeliveryPipcarModalState extends State<DeliveryPipcarModal> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.countdownSeconds;
    unawaited(SystemSound.play(SystemSoundType.alert));
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        widget.onReject();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = _secondsLeft / widget.countdownSeconds;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
                  isDark ? AppColors.panelDarkLow : AppColors.panelLightLow,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.racingOrange.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: AppColors.raisedPanelShadows(isDark),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.racingOrangeLight.withValues(alpha: 0.95),
                            AppColors.racingOrangeDark.withValues(alpha: 0.92),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.insetPanelShadows(isDark),
                      ),
                      child: const Icon(
                        LucideIcons.package,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova corrida',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.racingOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.order.storeName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonGreen.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'R\$ ${widget.order.deliveryFee.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.black.withValues(alpha: 0.18),
                    color: AppColors.racingOrange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tempo para responder: ${_secondsLeft}s',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.racingOrange,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(
                        theme,
                        LucideIcons.mapPin,
                        'Entrega',
                        widget.order.deliveryAddress,
                      ),
                      if (widget.order.recipientName != null) ...[
                        const SizedBox(height: 8),
                        _row(
                          theme,
                          LucideIcons.user,
                          'Destinatário',
                          widget.order.recipientName!,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _row(
                        theme,
                        LucideIcons.navigation,
                        'Distância até a loja',
                        widget.distanceToStoreKm != null
                            ? '${widget.distanceToStoreKm!.toStringAsFixed(1)} km'
                            : '${widget.order.totalDistance.toStringAsFixed(1)} km',
                      ),
                      if (widget.routeDistanceKm != null) ...[
                        const SizedBox(height: 8),
                        _row(
                          theme,
                          LucideIcons.map,
                          'Rota loja-cliente',
                          '${widget.routeDistanceKm!.toStringAsFixed(1)} km',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onReject,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: theme.dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Recusar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: widget.onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.racingOrangeDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.check, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Aceitar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.racingOrange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
