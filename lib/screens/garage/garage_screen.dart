import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../../services/api_service.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  Map<String, dynamic>? _deliveryRegistration;

  @override
  void initState() {
    super.initState();
    _loadDeliveryRegistrationIfNeeded();
  }

  Future<void> _loadDeliveryRegistrationIfNeeded() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null || user.pilotProfile.toUpperCase() != 'TRABALHO') return;
    try {
      final reg = await ApiService.getDeliveryRegistrationStatus();
      if (mounted) setState(() => _deliveryRegistration = reg);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike;
    final theme = Theme.of(context);

    // Se não houver bike, mostrar mensagem
    if (bike == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ModernHeader(
                title: 'Garagem',
                showBackButton: true,
                onBackPressed: () {
                  Provider.of<NavigationProvider>(context, listen: false).navigateTo(2);
                },
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
                        'Nenhuma moto cadastrada',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cadastre uma moto para gerenciar sua garagem.',
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            ModernHeader(
              title: 'Garagem',
              showBackButton: true,
              onBackPressed: () {
                Provider.of<NavigationProvider>(context, listen: false).navigateTo(2);
              },
            ),
            
            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card principal da moto
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
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.racingOrange.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.racingOrange.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.racingOrange,
                                      AppColors.racingOrangeLight,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  LucideIcons.bike,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${bike.brand} ${bike.model}',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.racingOrange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.racingOrange.withOpacity(0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.hash,
                                            color: AppColors.racingOrange,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            bike.plate,
                                            style: TextStyle(
                                              color: AppColors.racingOrange,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Seção de informações
                    Text(
                      'Informações',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Grid de informações
                    _buildInfoCard(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.gauge,
                      label: 'Quilometragem',
                      value: '${bike.currentKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} km',
                      color: AppColors.racingOrange,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.droplet,
                      label: 'Tipo de Óleo',
                      value: bike.oilType,
                      color: AppColors.racingOrangeLight,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context: context,
                            theme: theme,
                            icon: LucideIcons.circle,
                            label: 'Pneu Dianteiro',
                            value: '${bike.frontTirePressure} bar',
                            color: AppColors.statusOk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context: context,
                            theme: theme,
                            icon: LucideIcons.circle,
                            label: 'Pneu Traseiro',
                            value: '${bike.rearTirePressure} bar',
                            color: AppColors.statusOk,
                          ),
                        ),
                      ],
                    ),
                    if (_deliveryRegistration != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Dados de entregador',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDeliveryExtraSection(context, theme),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryExtraSection(BuildContext context, ThemeData theme) {
    final reg = _deliveryRegistration!;
    final lastOil = reg['lastOilChangeDate'] != null || reg['lastOilChangeKm'] != null;
    final lastOilDate = reg['lastOilChangeDate'] as String?;
    final lastOilKm = reg['lastOilChangeKm'] as int?;
    final emergencyPhone = reg['emergencyPhone'] as String?;
    final parts = <Widget>[];
    if (lastOil) {
      final text = [
        if (lastOilDate != null) 'Última troca: $lastOilDate',
        if (lastOilKm != null) '${lastOilKm.toString()} km',
      ].join(' • ');
      parts.add(
        _buildInfoCard(
          context: context,
          theme: theme,
          icon: LucideIcons.droplet,
          label: 'Última troca de óleo',
          value: text.isNotEmpty ? text : '--',
          color: AppColors.racingOrangeLight,
        ),
      );
      parts.add(const SizedBox(height: 12));
    }
    if (emergencyPhone != null && emergencyPhone.isNotEmpty) {
      parts.add(
        _buildInfoCard(
          context: context,
          theme: theme,
          icon: LucideIcons.phone,
          label: 'Telefone de emergência',
          value: emergencyPhone,
          color: AppColors.statusOk,
        ),
      );
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
