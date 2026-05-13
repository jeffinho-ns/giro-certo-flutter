import 'package:flutter/material.dart';

import '../../../utils/colors.dart';
import '../delivery_trip_controller.dart';

class TripNavigationHud extends StatelessWidget {
  const TripNavigationHud({
    super.key,
    required this.phase,
    required this.stageLabel,
    required this.destination,
    required this.instruction,
    required this.distanceLabel,
    required this.etaLabel,
    required this.statusLabel,
    required this.isBuildingRoute,
    this.errorMessage,
  });

  final DeliveryTripPhase phase;
  final String stageLabel;
  final String destination;
  final String instruction;
  final String distanceLabel;
  final String etaLabel;
  final String statusLabel;
  final bool isBuildingRoute;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _TripHudCard(
            key: ValueKey<String>(phase.name),
            stageLabel: stageLabel,
            destination: destination,
            instruction: instruction,
            distanceLabel: distanceLabel,
            etaLabel: etaLabel,
            statusLabel: statusLabel,
            isDark: isDark,
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: AppColors.alertRed,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        if (isBuildingRoute && errorMessage == null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.racingOrange,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TripStageProgressIndicator extends StatelessWidget {
  const TripStageProgressIndicator({super.key, required this.phase});

  final DeliveryTripPhase phase;

  @override
  Widget build(BuildContext context) {
    final stepOneActive = phase != DeliveryTripPhase.headingToClient;
    final stepTwoActive = phase == DeliveryTripPhase.headingToClient;

    return Row(
      children: [
        _StepDot(
          label: 'Loja',
          active: stepOneActive,
          completed: stepTwoActive,
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  stepTwoActive
                      ? AppColors.neonGreen
                      : AppColors.racingOrange.withValues(alpha: 0.85),
                  stepTwoActive
                      ? AppColors.neonGreen.withValues(alpha: 0.35)
                      : AppColors.racingOrange.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
        ),
        _StepDot(
          label: 'Cliente',
          active: stepTwoActive,
          completed: false,
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.active,
    required this.completed,
  });

  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? AppColors.neonGreen
        : active
            ? AppColors.racingOrange
            : Colors.white.withValues(alpha: 0.35);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: active ? 0.95 : 0.55),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TripHudCard extends StatelessWidget {
  const _TripHudCard({
    super.key,
    required this.stageLabel,
    required this.destination,
    required this.instruction,
    required this.distanceLabel,
    required this.etaLabel,
    required this.statusLabel,
    required this.isDark,
  });

  final String stageLabel;
  final String destination;
  final String instruction;
  final String distanceLabel;
  final String etaLabel;
  final String statusLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark
                  ? AppColors.panelDarkHigh.withValues(alpha: 0.94)
                  : AppColors.panelDarkHigh.withValues(alpha: 0.9),
              isDark
                  ? AppColors.panelDarkLow.withValues(alpha: 0.92)
                  : AppColors.panelDarkLow.withValues(alpha: 0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.racingOrange.withValues(alpha: 0.32),
          ),
          boxShadow: AppColors.raisedPanelShadows(true),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stageLabel,
              style: const TextStyle(
                color: AppColors.racingOrangeLight,
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
                fontSize: 19,
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
                color: Colors.white.withValues(alpha: 0.72),
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
            color: Colors.white.withValues(alpha: 0.58),
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
