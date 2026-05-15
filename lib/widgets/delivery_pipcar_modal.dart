import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/delivery_order.dart';
import '../services/delivery_offer_alert_feedback.dart';
import '../utils/colors.dart';
import '../utils/delivery_address_label.dart';

/// Oferta imersiva de corrida com contagem regressiva, som e vibração contínuos.
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
  final DeliveryOfferAlertFeedback _alertFeedback = DeliveryOfferAlertFeedback();
  bool _isClosing = false;
  /// Quando chega a zero o card continua; só para alerta contínuo (o rider deve aceitar ou recusar).
  bool _countdownEnded = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.countdownSeconds;
    unawaited(_alertFeedback.start());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isClosing) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        unawaited(_onCountdownReachedZero());
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _onCountdownReachedZero() async {
    if (!mounted || _isClosing) return;
    await _alertFeedback.stop();
    setState(() {
      _secondsLeft = 0;
      _countdownEnded = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_alertFeedback.stop());
    super.dispose();
  }

  Future<void> _closeOfferAsReject() async {
    if (_isClosing) return;
    _isClosing = true;
    _timer?.cancel();
    await _alertFeedback.stop();
    if (!mounted) return;
    widget.onReject();
  }

  Future<void> _handleAccept() async {
    if (_isClosing) return;
    _isClosing = true;
    _timer?.cancel();
    await _alertFeedback.stop();
    if (!mounted) return;
    widget.onAccept();
  }

  Future<void> _handleReject() async {
    await _closeOfferAsReject();
  }

  String get _distanceToStoreLabel {
    final distance = widget.distanceToStoreKm ?? widget.order.totalDistance;
    return '${distance.toStringAsFixed(1)} km';
  }

  String get _deliveryNeighborhood =>
      DeliveryAddressLabel.neighborhood(widget.order.deliveryAddress);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = _countdownEnded
        ? 1.0
        : (_secondsLeft / widget.countdownSeconds).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {},
      child: Material(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.98)
            : AppColors.lightBackground.withValues(alpha: 0.98),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova corrida disponível',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _countdownEnded
                                ? 'A corrida continua disponível. Aceite ou recuse para fechar.'
                                : 'Responda antes que outro motociclista aceite.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isClosing ? null : () => unawaited(_handleReject()),
                      tooltip: 'Recusar corrida',
                      icon: const Icon(LucideIcons.x, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 132,
                          height: 132,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: Colors.black.withValues(alpha: 0.12),
                            color: _secondsLeft <= 5
                                ? AppColors.alertRed
                                : AppColors.racingOrange,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _countdownEnded ? '—' : '$_secondsLeft',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            Text(
                              _countdownEnded ? 'aguardando' : 'segundos',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.neonGreen.withValues(alpha: 0.18),
                        AppColors.neonGreen.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Valor da corrida',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'R\$ ${widget.order.deliveryFee.toStringAsFixed(2)}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonGreen,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark
                              ? AppColors.panelDarkHigh
                              : AppColors.panelLightHigh,
                          isDark
                              ? AppColors.panelDarkLow
                              : AppColors.panelLightLow,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.racingOrange.withValues(alpha: 0.28),
                      ),
                      boxShadow: AppColors.raisedPanelShadows(isDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _infoTile(
                          theme: theme,
                          icon: LucideIcons.store,
                          label: 'Lojista',
                          value: widget.order.storeName,
                        ),
                        const SizedBox(height: 14),
                        _infoTile(
                          theme: theme,
                          icon: LucideIcons.navigation,
                          label: 'Distância até a loja',
                          value: _distanceToStoreLabel,
                        ),
                        const SizedBox(height: 14),
                        _infoTile(
                          theme: theme,
                          icon: LucideIcons.mapPin,
                          label: 'Bairro de entrega',
                          value: _deliveryNeighborhood,
                        ),
                        if (widget.routeDistanceKm != null) ...[
                          const SizedBox(height: 14),
                          _infoTile(
                            theme: theme,
                            icon: LucideIcons.map,
                            label: 'Rota loja-cliente',
                            value:
                                '${widget.routeDistanceKm!.toStringAsFixed(1)} km',
                          ),
                        ],
                        const Spacer(),
                        Text(
                          widget.order.deliveryAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: math.max(58, MediaQuery.sizeOf(context).height * 0.075),
                  child: ElevatedButton(
                    onPressed: _isClosing ? null : () => unawaited(_handleAccept()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.checkCircle, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Aceitar corrida',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isClosing ? null : () => unawaited(_handleReject()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alertRed,
                      side: BorderSide(
                        color: AppColors.alertRed.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.xCircle, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Recusar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _infoTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.racingOrange.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.racingOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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
