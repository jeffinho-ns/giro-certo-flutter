import 'package:flutter/material.dart';
import '../utils/colors.dart';

class StatusCircleWidget extends StatelessWidget {
  final String label;
  final double percentage; // 0.0 a 1.0
  final String status; // OK, Atenção, Crítico

  const StatusCircleWidget({
    super.key,
    required this.label,
    required this.percentage,
    required this.status,
  });

  Color getStatusColor() {
    if (percentage >= 0.7) return AppColors.statusOk;
    if (percentage >= 0.4) return AppColors.statusWarning;
    return AppColors.statusCritical;
  }

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor();
    
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 8,
                  backgroundColor: AppColors.mediumGray,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
