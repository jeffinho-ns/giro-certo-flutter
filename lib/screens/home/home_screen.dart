import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/maintenance.dart';
import '../../utils/colors.dart';
import '../../widgets/status_circle_widget.dart';
import '../../widgets/critical_alert_card.dart';
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

    return Scaffold(
      backgroundColor: AppColors.darkGrafite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com foto da moto e placa
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkGray,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bike.brand} ${bike.model}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.racingOrange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.racingOrange),
                              ),
                              child: Text(
                                bike.plate,
                                style: const TextStyle(
                                  color: AppColors.racingOrange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.mediumGray,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            LucideIcons.bike,
                            size: 50,
                            color: AppColors.racingOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Odómetro digital
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.racingOrange.withOpacity(0.2),
                            AppColors.racingOrange.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.racingOrange.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Quilometragem Total',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${bike.currentKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} km',
                            style: const TextStyle(
                              color: AppColors.racingOrange,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Status circulares
                    const Text(
                      'Status Rápido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StatusCircleWidget(
                          label: 'Óleo',
                          percentage: oilMaintenance.healthPercentage,
                          status: oilMaintenance.status,
                        ),
                        StatusCircleWidget(
                          label: 'Pneus',
                          percentage: tireMaintenance.healthPercentage,
                          status: tireMaintenance.status,
                        ),
                        StatusCircleWidget(
                          label: 'Travões',
                          percentage: brakeMaintenance.healthPercentage,
                          status: brakeMaintenance.status,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Card de Atenção Crítica
                    if (criticalMaintenances.isNotEmpty)
                      CriticalAlertCard(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
