import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/maintenance.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import 'package:intl/intl.dart';

class MaintenanceDetailScreen extends StatelessWidget {
  const MaintenanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike!;
    final maintenances = MockDataService.getMockMaintenances(bike.currentKm);
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
          children: [
            // Header
            const ModernHeader(
              title: 'Manutenção Detalhada',
              showBackButton: false,
            ),
            
            // Lista de manutenções
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: maintenances.length,
                itemBuilder: (context, index) {
                  final maintenance = maintenances[index];
                  return _buildModernMaintenanceCard(maintenance, theme);
                },
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildModernMaintenanceCard(Maintenance maintenance, ThemeData theme) {
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maintenance.partName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      maintenance.category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  maintenance.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Barra de progresso moderna
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.activity,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Saúde: ${(maintenance.healthPercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${maintenance.remainingKm} km restantes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: maintenance.healthPercentage,
                  minHeight: 10,
                  backgroundColor: statusColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Informações em grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    theme: theme,
                    icon: LucideIcons.clock,
                    label: 'Última Troca',
                    value: '${NumberFormat('#,###').format(maintenance.lastChangeKm)} km',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.dividerColor,
                ),
                Expanded(
                  child: _buildInfoItem(
                    theme: theme,
                    icon: LucideIcons.target,
                    label: 'Recomendado',
                    value: '${NumberFormat('#,###').format(maintenance.recommendedChangeKm)} km',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
