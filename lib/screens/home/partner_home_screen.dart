import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/api_service.dart';
import '../../models/delivery_order.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../delivery/create_delivery_modal.dart';
import '../delivery/delivery_detail_modal.dart';
import '../delivery/delivery_screen.dart';

/// Home do lojista (parceiro): dashboard com Novo Pedido, resumo e listas de pedidos.
/// Não usa o mapa; mantém o layout original.
class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
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
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null || !user.isPartner) return;

    setState(() => _isLoading = true);
    try {
      final allOrders = await ApiService.getDeliveryOrders(storeId: user.partnerId);
      final activeOrders = allOrders
          .where((o) =>
              o.status == DeliveryStatus.accepted || o.status == DeliveryStatus.inProgress)
          .toList();
      final pendingOrders = allOrders.where((o) => o.status == DeliveryStatus.pending).toList();
      final completedOrders = allOrders.where((o) => o.status == DeliveryStatus.completed).toList();
      final today = DateTime.now();
      final todayOrders = completedOrders.where((o) =>
          o.completedAt != null &&
          o.completedAt!.year == today.year &&
          o.completedAt!.month == today.month &&
          o.completedAt!.day == today.day);
      final revenue = todayOrders.fold<double>(0.0, (sum, order) => sum + order.totalValue);

      if (!mounted) return;
      setState(() {
        _activeOrders = activeOrders;
        _pendingOrders = pendingOrders;
        _totalOrders = allOrders.length;
        _completedOrders = completedOrders.length;
        _totalRevenue = revenue;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const ModernHeader(title: 'Minha Loja'),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildPartnerContent(theme),
                ),
        ),
      ],
    );
  }

  Widget _buildPartnerContent(ThemeData theme) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.user;
    final userLat = user?.currentLat ?? -23.5505;
    final userLng = user?.currentLng ?? -46.6333;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CreateDeliveryModal(
                userLat: userLat,
                userLng: userLng,
                onOrderCreated: _loadPartnerData,
              ),
            ).then((_) => _loadPartnerData());
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
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
                  child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
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
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
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
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.3), width: 1.5),
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
                  Icon(LucideIcons.dollarSign, color: AppColors.neonGreen, size: 20),
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
                  Provider.of<NavigationProvider>(context, listen: false).navigateTo(5);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeliveryScreen()),
                  );
                },
                child: Text(
                  'Ver todos',
                  style: TextStyle(color: AppColors.racingOrange, fontWeight: FontWeight.w600),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeliveryScreen()),
                  );
                },
                child: Text(
                  'Ver todos',
                  style: TextStyle(color: AppColors.racingOrange, fontWeight: FontWeight.w600),
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
        const SizedBox(height: 100),
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
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildOrderCard(
    BuildContext context,
    ThemeData theme,
    DeliveryOrder order, {
    required bool isActive,
  }) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    final userLat = user?.currentLat ?? -23.5505;
    final userLng = user?.currentLng ?? -46.6333;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DeliveryDetailModal(
            order: order,
            userLat: userLat,
            userLng: userLng,
            onOrderUpdated: _loadPartnerData,
          ),
        ).then((_) => _loadPartnerData());
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
                    color: (isActive ? AppColors.statusOk : AppColors.statusWarning).withOpacity(0.15),
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
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  style: const TextStyle(
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
                  Icon(LucideIcons.user, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
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
}
