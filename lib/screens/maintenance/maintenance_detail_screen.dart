import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/maintenance.dart';
import '../../utils/colors.dart';
import 'package:intl/intl.dart';

class MaintenanceDetailScreen extends StatelessWidget {
  const MaintenanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike!;
    final maintenances = MockDataService.getMockMaintenances(bike.currentKm);

    return Scaffold(
      backgroundColor: AppColors.darkGrafite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manutenção Detalhada'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: maintenances.length,
        itemBuilder: (context, index) {
          final maintenance = maintenances[index];
          return _buildMaintenanceCard(maintenance);
        },
      ),
    );
  }

  Widget _buildMaintenanceCard(Maintenance maintenance) {
    Color statusColor;
    IconData statusIcon;
    
    if (maintenance.status == 'OK') {
      statusColor = AppColors.statusOk;
      statusIcon = LucideIcons.checkCircle;
    } else if (maintenance.status == 'Atenção') {
      statusColor = AppColors.statusWarning;
      statusIcon = LucideIcons.alertCircle;
    } else {
      statusColor = AppColors.statusCritical;
      statusIcon = LucideIcons.alertTriangle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  maintenance.partName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      maintenance.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            maintenance.category,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Barra de Vida
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saúde: ${(maintenance.healthPercentage * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${maintenance.remainingKm} km restantes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: maintenance.healthPercentage,
                  minHeight: 12,
                  backgroundColor: AppColors.mediumGray,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Última Troca',
                  '${NumberFormat('#,###').format(maintenance.lastChangeKm)} km',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Recomendado',
                  '${NumberFormat('#,###').format(maintenance.recommendedChangeKm)} km',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
