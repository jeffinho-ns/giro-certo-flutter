import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/maintenance.dart';
import '../../models/partner.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../partners/voucher_modal.dart';
import 'package:intl/intl.dart';

class MaintenanceDetailScreen extends StatelessWidget {
  const MaintenanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike;
    final theme = Theme.of(context);

    // Se não houver bike, mostrar mensagem
    if (bike == null) {
      return SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ModernHeader(
              title: 'Manutenção Detalhada',
              showBackButton: false,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.bike,
                      size: 64,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Configure sua moto na garagem',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Para visualizar as manutenções, você precisa cadastrar uma moto.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final maintenances = MockDataService.getMockMaintenances(bike.currentKm);

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
                  return _buildModernMaintenanceCard(context, maintenance, theme);
                },
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildModernMaintenanceCard(BuildContext context, Maintenance maintenance, ThemeData theme) {
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
          
          // Sugestão de parceiro para itens com status Atenção ou Crítico
          if (maintenance.status == 'Atenção' || maintenance.status == 'Crítico')
            _buildPartnerSuggestion(context, maintenance, theme),
        ],
      ),
    );
  }

  Widget _buildPartnerSuggestion(BuildContext context, Maintenance maintenance, ThemeData theme) {
    // Localização simulada do usuário
    const double userLatitude = -23.5505;
    const double userLongitude = -46.6333;
    
    final partners = MockDataService.getMockPartners();
    
    // Encontrar parceiros relevantes que tenham promoções para a categoria
    final relevantPartners = partners.where((partner) {
      // Verifica se o parceiro tem especialidade na categoria ou promoção relacionada
      final hasSpecialty = partner.specialties.any(
        (specialty) => specialty.toLowerCase() == maintenance.category.toLowerCase()
      );
      final hasPromotion = partner.activePromotions.any(
        (promo) => promo.category?.toLowerCase() == maintenance.category.toLowerCase()
      );
      return (hasSpecialty || hasPromotion) && partner.activePromotions.isNotEmpty;
    }).toList();
    
    if (relevantPartners.isEmpty) return const SizedBox.shrink();
    
    // Ordenar por distância
    relevantPartners.sort((a, b) => 
      a.distanceTo(userLatitude, userLongitude)
        .compareTo(b.distanceTo(userLatitude, userLongitude))
    );
    
    final nearestPartner = relevantPartners.first;
    final distance = nearestPartner.distanceTo(userLatitude, userLongitude);
    final relevantPromotion = nearestPartner.activePromotions.firstWhere(
      (promo) => promo.category?.toLowerCase() == maintenance.category.toLowerCase(),
      orElse: () => nearestPartner.activePromotions.first,
    );

    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.racingOrange.withOpacity(0.2),
                AppColors.racingOrange.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.racingOrange.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.racingOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.store,
                      color: AppColors.racingOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precisa trocar este item?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.racingOrange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Veja a ${nearestPartner.type == PartnerType.store ? "Loja" : "Oficina"} ${nearestPartner.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'A ${distance.toStringAsFixed(1)} km de distância',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (nearestPartner.isTrusted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            size: 12,
                            color: AppColors.neonGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verificado',
                            style: TextStyle(
                              color: AppColors.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (relevantPromotion.discountPercentage > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.racingOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.tag,
                        size: 16,
                        color: AppColors.racingOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${relevantPromotion.discountPercentage.toInt()}% de desconto via Giro Certo',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.racingOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => VoucherModal(
                        partner: nearestPartner,
                        promotion: relevantPromotion,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.racingOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Ver Oferta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.arrowRight,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
