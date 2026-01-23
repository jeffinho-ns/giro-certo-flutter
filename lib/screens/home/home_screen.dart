import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/api_service.dart';
import '../../services/mock_data_service.dart';
import '../../models/delivery_order.dart';
import '../../models/bike.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/floating_bottom_nav.dart';
import '../maintenance/maintenance_detail_screen.dart';
import '../delivery/create_delivery_modal.dart';
import '../delivery/delivery_detail_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  List<DeliveryOrder> _activeOrders = [];
  List<DeliveryOrder> _pendingOrders = [];
  int _totalOrders = 0;
  int _completedOrders = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  Future<void> _loadPartnerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final user = appState.user;

      if (user == null || !user.isPartner) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Buscar pedidos do lojista
      final allOrders = await ApiService.getDeliveryOrders(storeId: user.partnerId);
      
      // Separar por status
      final activeOrders = allOrders.where((o) => 
        o.status == DeliveryStatus.accepted || 
        o.status == DeliveryStatus.inProgress
      ).toList();
      
      final pendingOrders = allOrders.where((o) => 
        o.status == DeliveryStatus.pending
      ).toList();
      
      final completedOrders = allOrders.where((o) => 
        o.status == DeliveryStatus.completed
      ).toList();

      // Calcular receita total (hoje)
      final today = DateTime.now();
      final todayOrders = completedOrders.where((o) => 
        o.completedAt != null &&
        o.completedAt!.year == today.year &&
        o.completedAt!.month == today.month &&
        o.completedAt!.day == today.day
      ).toList();

      final revenue = todayOrders.fold<double>(0.0, (sum, order) => sum + order.totalValue);

      setState(() {
        _activeOrders = activeOrders;
        _pendingOrders = pendingOrders;
        _totalOrders = allOrders.length;
        _completedOrders = completedOrders.length;
        _totalRevenue = revenue;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados do lojista: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.user;
    final bike = appState.bike;
    
    // Determinar se é motociclista ou lojista
    final isRider = user?.isRider ?? true;
    
    // Debug: verificar dados do usuário
    if (user != null) {
      print('🔍 Home - User: ${user.email}, partnerId: ${user.partnerId}, isPartner: ${user.isPartner}, isRider: ${user.isRider}');
    } else {
      print('⚠️ Home - User é null!');
    }
    
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Header moderno
        ModernHeader(
          title: isRider ? 'Dashboard' : 'Minha Loja',
        ),
        
        // Conteúdo principal
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isRider
                ? _buildRiderHome(context, theme, bike)
                : _buildPartnerHome(context, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderHome(BuildContext context, ThemeData theme, Bike? bike) {
    // Esta função só será chamada para motociclistas
    // Se não houver bike, mostrar mensagem
    if (bike == null) {
      return Center(
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
          ],
        ),
      );
    }

    // TODO: Integrar com API real quando disponível
    // Por enquanto, usar dados mockados apenas para desenvolvimento
    final maintenances = MockDataService.getMockMaintenances(bike.currentKm);
    
    final oilMaintenance = maintenances.firstWhere((m) => m.category == 'Óleo');
    final tireMaintenance = maintenances.firstWhere((m) => m.category == 'Pneus');
    final brakeMaintenance = maintenances.firstWhere((m) => m.category == 'Travões');
    
    final criticalMaintenances = maintenances.where((m) => m.status == 'Crítico' || m.status == 'Atenção').toList();

    return Column(
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
    );
  }

  Widget _buildPartnerHome(BuildContext context, ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão grande para criar novo pedido
        GestureDetector(
          onTap: () {
            final appState = Provider.of<AppStateProvider>(context, listen: false);
            final user = appState.user;
            
            // Usar localização padrão se não houver GPS
            final userLat = user?.currentLat ?? -23.5505;
            final userLng = user?.currentLng ?? -46.6333;
            
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CreateDeliveryModal(
                userLat: userLat,
                userLng: userLng,
                onOrderCreated: () {
                  _loadPartnerData();
                },
              ),
            ).then((_) {
              // Recarregar dados após criar pedido
              _loadPartnerData();
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.racingOrange,
                  AppColors.racingOrangeLight,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.racingOrange.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Novo Pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Criar uma nova entrega',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Cards de resumo
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                theme: theme,
                number: '$_totalOrders',
                label: 'Total',
                icon: LucideIcons.package,
                color: AppColors.racingOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                theme: theme,
                number: '${_pendingOrders.length}',
                label: 'Pendentes',
                icon: LucideIcons.clock,
                color: AppColors.statusWarning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                theme: theme,
                number: '$_completedOrders',
                label: 'Concluídos',
                icon: LucideIcons.checkCircle,
                color: AppColors.statusOk,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Card de Receita
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neonGreen.withOpacity(0.15),
                AppColors.neonGreen.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.neonGreen.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonGreen.withOpacity(0.1),
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
                    LucideIcons.dollarSign,
                    color: AppColors.neonGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Receita Total (Hoje)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'R\$ ${_totalRevenue.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        
        // Pedidos em Andamento (para rastrear)
        if (_activeOrders.isNotEmpty) ...[
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Em Andamento',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  final navProvider = Provider.of<NavigationProvider>(context, listen: false);
                  navProvider.navigateTo(5);
                },
                child: Text(
                  'Ver todos',
                  style: TextStyle(
                    color: AppColors.racingOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._activeOrders.take(3).map((order) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOrderCard(context, theme, order, isActive: true),
          )),
        ],
        
        // Pedidos Pendentes (para aprovar)
        if (_pendingOrders.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aguardando Aprovação',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  final navProvider = Provider.of<NavigationProvider>(context, listen: false);
                  navProvider.navigateTo(5);
                },
                child: Text(
                  'Ver todos',
                  style: TextStyle(
                    color: AppColors.racingOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._pendingOrders.take(3).map((order) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOrderCard(context, theme, order, isActive: false),
          )),
        ],
        
        const SizedBox(height: 100), // Espaço para o bottom nav
      ],
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    ThemeData theme,
    DeliveryOrder order,
    {required bool isActive}
  ) {
    return GestureDetector(
      onTap: () {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        final user = appState.user;
        
        // Usar localização padrão se não houver GPS
        final userLat = user?.currentLat ?? -23.5505;
        final userLng = user?.currentLng ?? -46.6333;
        
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DeliveryDetailModal(
            order: order,
            userLat: userLat,
            userLng: userLng,
            onOrderUpdated: () {
              _loadPartnerData();
            },
          ),
        ).then((_) {
          _loadPartnerData();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? AppColors.statusOk.withOpacity(0.3)
                : AppColors.statusWarning.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.statusOk : AppColors.statusWarning)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? LucideIcons.truck : LucideIcons.clock,
                    color: isActive ? AppColors.statusOk : AppColors.statusWarning,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.recipientName ?? 'Sem nome',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${order.totalValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isActive && order.riderName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Entregador: ${order.riderName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
