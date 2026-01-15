import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/maintenance.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/floating_bottom_nav.dart';
import '../maintenance/maintenance_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike!;
    final maintenances = MockDataService.getMockMaintenances(bike.currentKm);
    
    final oilMaintenance = maintenances.firstWhere((m) => m.category == 'Óleo');
    final tireMaintenance = maintenances.firstWhere((m) => m.category == 'Pneus');
    final brakeMaintenance = maintenances.firstWhere((m) => m.category == 'Travões');
    
    final criticalMaintenances = maintenances.where((m) => m.status == 'Crítico' || m.status == 'Atenção').toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Header moderno
        const ModernHeader(title: ''),
        
        // Conteúdo principal
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cards de resumo diário
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        theme: theme,
                        number: '4',
                        label: 'Manutenções',
                        icon: LucideIcons.wrench,
                        color: AppColors.racingOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        theme: theme,
                        number: '6',
                        label: 'Itens',
                        icon: LucideIcons.list,
                        color: AppColors.racingOrangeLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        theme: theme,
                        number: '2',
                        label: 'Concluídos',
                        icon: LucideIcons.checkCircle,
                        color: AppColors.statusOk,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Seção de Status Rápido
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Rápido',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MaintenanceDetailScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Ver tudo',
                        style: TextStyle(
                          color: AppColors.racingOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Cards de status
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        context: context,
                        theme: theme,
                        label: 'Óleo',
                        percentage: oilMaintenance.healthPercentage,
                        status: oilMaintenance.status,
                        icon: LucideIcons.droplet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatusCard(
                        context: context,
                        theme: theme,
                        label: 'Pneus',
                        percentage: tireMaintenance.healthPercentage,
                        status: tireMaintenance.status,
                        icon: LucideIcons.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatusCard(
                        context: context,
                        theme: theme,
                        label: 'Freios',
                        percentage: brakeMaintenance.healthPercentage,
                        status: brakeMaintenance.status,
                        icon: LucideIcons.shield,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Card de Quilometragem
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.racingOrange.withOpacity(0.15),
                        AppColors.racingOrange.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.racingOrange.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.racingOrange.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.gauge,
                            color: AppColors.racingOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quilometragem Total',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${bike.currentKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: TextStyle(
                          color: AppColors.racingOrange,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'km',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Alerta crítico
                if (criticalMaintenances.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildAlertCard(
                    context: context,
                    theme: theme,
                    title: 'Atenção Necessária',
                    message: '${criticalMaintenances.length} item(ns) precisa(m) de atenção',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MaintenanceDetailScreen(),
                        ),
                      );
                    },
                  ),
                ],
                
                const SizedBox(height: 100), // Espaço para o bottom nav
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required ThemeData theme,
    required String number,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required double percentage,
    required String status,
    required IconData icon,
  }) {
    Color statusColor;
    if (percentage >= 0.7) {
      statusColor = AppColors.statusOk;
    } else if (percentage >= 0.4) {
      statusColor = AppColors.statusWarning;
    } else {
      statusColor = AppColors.statusCritical;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(
              color: statusColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String message,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.alertRed.withOpacity(0.15),
              AppColors.alertRed.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.alertRed.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.alertRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.alertRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.alertRed,
            ),
          ],
        ),
      ),
    );
  }
}
