import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/colors.dart';

class CriticalAlertCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onTap;
  /// Quando false, usa cor de atenção (laranja) em vez de crítico (vermelho).
  final bool isCritical;

  const CriticalAlertCard({
    super.key,
    required this.title,
    required this.message,
    this.onTap,
    this.isCritical = true,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCritical ? AppColors.alertRed : AppColors.statusWarning;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCritical
                    ? LucideIcons.alertTriangle
                    : LucideIcons.alertCircle,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
