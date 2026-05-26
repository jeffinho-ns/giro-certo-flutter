import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../models/delivery_order.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import 'delivery_detail_modal.dart';

/// Tela de histórico de entregas. Mostra:
/// - Lojista: pedidos da sua loja (concluídos ou cancelados).
/// - Delivery: pedidos que o entregador concluiu/cancelou.
class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  List<DeliveryOrder> _orders = const [];
  bool _loading = true;
  String? _error;
  DeliveryStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<DeliveryOrder> orders;
      if (user?.isPartner == true && user?.partnerId != null) {
        orders = await ApiService.getDeliveryOrders(
          storeId: user!.partnerId!,
          limit: 200,
        );
      } else if (user != null) {
        orders = await ApiService.getDeliveryOrders(
          riderId: user.id,
          limit: 200,
        );
      } else {
        orders = [];
      }
      orders = orders
          .where((o) =>
              o.status == DeliveryStatus.completed ||
              o.status == DeliveryStatus.cancelled)
          .toList();
      orders.sort((a, b) {
        final aDate = a.completedAt ?? a.createdAt;
        final bDate = b.completedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar o histórico.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _filter == null
        ? _orders
        : _orders.where((o) => o.status == _filter).toList();
    final totalEarned = visible.fold<double>(
      0,
      (sum, o) => sum + (o.status == DeliveryStatus.completed ? o.deliveryFee : 0),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Histórico de entregas',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.racingOrange.withOpacity(0.18),
                      AppColors.racingOrangeDark.withOpacity(0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _summary(theme,
                          icon: LucideIcons.package,
                          label: 'Total',
                          value: visible.length.toString()),
                    ),
                    Expanded(
                      child: _summary(theme,
                          icon: LucideIcons.checkCircle,
                          label: 'Concluídos',
                          value: visible
                              .where((o) =>
                                  o.status == DeliveryStatus.completed)
                              .length
                              .toString()),
                    ),
                    Expanded(
                      child: _summary(theme,
                          icon: LucideIcons.dollarSign,
                          label: 'Ganhos',
                          value:
                              'R\$ ${totalEarned.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('Todos', _filter == null,
                      onTap: () => setState(() => _filter = null)),
                  _chip('Concluídos', _filter == DeliveryStatus.completed,
                      onTap: () => setState(
                          () => _filter = DeliveryStatus.completed)),
                  _chip('Cancelados', _filter == DeliveryStatus.cancelled,
                      onTap: () => setState(
                          () => _filter = DeliveryStatus.cancelled)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _errorState(theme)
                        : visible.isEmpty
                            ? _emptyState(theme)
                            : ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: visible.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) =>
                                    _OrderTile(order: visible[i]),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(ThemeData theme,
      {required IconData icon,
      required String label,
      required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.racingOrange, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _chip(String label, bool selected, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.racingOrange.withOpacity(0.2),
        labelStyle: TextStyle(
          color: selected ? AppColors.racingOrange : null,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(LucideIcons.history,
            size: 48,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Sem entregas no histórico ainda.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _errorState(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(LucideIcons.cloudOff,
            size: 48, color: AppColors.statusWarning),
        const SizedBox(height: 12),
        Center(
          child: Text(_error ?? '', style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: _load,
            child: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  final DeliveryOrder order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final isCompleted = order.status == DeliveryStatus.completed;
    final color = isCompleted ? AppColors.statusOk : AppColors.alertRed;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DeliveryDetailModal(
              order: order,
              userLat: order.storeLatitude,
              userLng: order.storeLongitude,
              showRouteHistory: true,
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? LucideIcons.checkCircle
                      : LucideIcons.xCircle,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.storeName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFmt
                          .format(order.completedAt ?? order.createdAt),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${order.deliveryFee.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (order.distance != null)
                    Text(
                      '${order.distance!.toStringAsFixed(1)} km',
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
