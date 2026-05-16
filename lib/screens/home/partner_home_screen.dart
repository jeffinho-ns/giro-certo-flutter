import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../models/partner.dart';
import '../../models/delivery_order.dart';
import '../../utils/colors.dart';
import '../../utils/delivery_status_utils.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/api_image.dart';
import '../../widgets/partner_delivery_status_tracker.dart';
import '../../widgets/partner_rider_detail_sheet.dart';
import '../delivery/create_delivery_modal.dart';
import '../delivery/delivery_detail_modal.dart';
import '../delivery/delivery_screen.dart';

/// Home do lojista: painel de pedidos em tempo real (sem mapa).
class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  List<DeliveryOrder> _allOrders = [];
  List<DeliveryOrder> _activeOrders = [];
  List<DeliveryOrder> _awaitingDispatchOrders = [];
  List<DeliveryOrder> _pendingOrders = [];
  final Set<String> _dispatchingOrderIds = <String>{};
  final Set<String> _knownOrderIds = <String>{};
  final Set<String> _riderArrivedDialogOrderIds = <String>{};
  Partner? _myPartner;
  int _totalOrders = 0;
  int _completedOrders = 0;
  double _totalRevenue = 0.0;
  StreamSubscription<Map<String, dynamic>>? _deliveryStatusSubscription;
  Timer? _realtimeReloadDebounce;
  Timer? _partnerBackgroundSyncTimer;
  String? _subscribedPartnerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeRealtimeUpdates();
      _loadPartnerData();
    });
    _partnerBackgroundSyncTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final u = appState.user;
      if (u != null && u.isPartner && u.partnerId != null) {
        _loadPartnerData(silent: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeRealtimeUpdates();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPartnerData(silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deliveryStatusSubscription?.cancel();
    _realtimeReloadDebounce?.cancel();
    _partnerBackgroundSyncTimer?.cancel();
    super.dispose();
  }

  void _subscribeRealtimeUpdates() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    final userId = user?.id;
    final partnerId = user?.partnerId;
    if (userId == null || partnerId == null || !user!.isPartner) return;
    if (_subscribedPartnerId == partnerId && _deliveryStatusSubscription != null) {
      return;
    }

    _deliveryStatusSubscription?.cancel();
    _subscribedPartnerId = partnerId;
    RealtimeService.instance.connect(userId);
    _deliveryStatusSubscription =
        RealtimeService.instance.onDeliveryStatusChanged.listen(
      _handleRealtimeDeliveryEvent,
    );
  }

  void _handleRealtimeDeliveryEvent(Map<String, dynamic> payload) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final partnerId = appState.user?.partnerId;
    if (partnerId == null) return;

    if (payload['_storeRefresh'] == true) {
      final sid = payload['storeId']?.toString();
      if (sid != null && sid == partnerId.toString()) {
        _loadPartnerData(silent: true);
      }
      return;
    }

    final orderRaw = payload['order'];
    if (orderRaw is Map<String, dynamic>) {
      try {
        final order = ApiService.deliveryOrderFromJson(
          Map<String, dynamic>.from(orderRaw),
        );
        if (order.storeId.toString() != partnerId.toString()) return;

        _maybeShowRiderArrivedDialog(order);

        final isNewOrder = !_knownOrderIds.contains(order.id);
        final merged = <DeliveryOrder>[
          order,
          ..._allOrders.where((existing) => existing.id != order.id),
        ];
        _syncFromOrderList(merged);
        if (isNewOrder &&
            (DeliveryStatusUtils.isAwaitingDispatch(order.status) ||
                DeliveryStatusUtils.isPending(order.status)) &&
            mounted) {
          final fromWa = (order.notes ?? '').toLowerCase().contains('whatsapp');
          final msg = DeliveryStatusUtils.isPending(order.status)
              ? (fromWa
                  ? 'Novo chamado (WhatsApp): motos já estão sendo notificadas.'
                  : 'Novo chamado: buscando motociclista.')
              : 'Novo pedido na loja — confirme para chamar motociclistas.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
        return;
      } catch (e) {
        debugPrint('Falha ao aplicar pedido em tempo real: $e');
      }
    }

    _scheduleRealtimeReload();
  }

  void _maybeShowRiderArrivedDialog(DeliveryOrder order) {
    if (order.status != DeliveryStatus.arrivedAtStore) return;
    if ((order.riderId ?? '').isEmpty) return;
    if (_riderArrivedDialogOrderIds.contains(order.id)) return;
    _riderArrivedDialogOrderIds.add(order.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('${order.riderName ?? 'Motociclista'} chegou'),
            content: const Text(
              'O entregador está na loja. Toque no card do pedido para ver foto, moto e código de retirada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Ver depois'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  PartnerRiderDetailSheet.show(context, order);
                },
                child: const Text('Ver entregador'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _openDeliveryIssueReport(DeliveryOrder order) async {
    final subject = Uri.encodeComponent('Problema no pedido ${order.id}');
    final body = Uri.encodeComponent(
      'Descreva o ocorrido:\n\n'
      'Pedido: ${order.id}\n'
      'Estado no app: ${order.status.name}\n'
      'Destino: ${order.deliveryAddress}\n',
    );
    final uri = Uri.parse('mailto:suporte@girocerto.com.br?subject=$subject&body=$body');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o e-mail. Contacte o suporte com o ID do pedido.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir relatório: $e')),
        );
      }
    }
  }

  void _scheduleRealtimeReload() {
    _realtimeReloadDebounce?.cancel();
    _realtimeReloadDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadPartnerData(silent: true),
    );
  }

  void _syncFromOrderList(List<DeliveryOrder> allOrders) {
    final activeOrders = allOrders
        .where((o) => DeliveryStatusUtils.isActive(o.status))
        .toList();
    final awaitingDispatchOrders = allOrders
        .where((o) => DeliveryStatusUtils.isAwaitingDispatch(o.status))
        .toList();
    final pendingOrders = allOrders
        .where((o) => DeliveryStatusUtils.isPending(o.status))
        .toList();
    final completedOrders =
        allOrders.where((o) => o.status == DeliveryStatus.completed).toList();
    final today = DateTime.now();
    final todayOrders = completedOrders.where((o) =>
        o.completedAt != null &&
        o.completedAt!.year == today.year &&
        o.completedAt!.month == today.month &&
        o.completedAt!.day == today.day);
    final revenue =
        todayOrders.fold<double>(0.0, (sum, order) => sum + order.totalValue);

    if (!mounted) return;
    setState(() {
      _allOrders = allOrders;
      _activeOrders = activeOrders;
      _awaitingDispatchOrders = awaitingDispatchOrders;
      _pendingOrders = pendingOrders;
      _totalOrders = allOrders.length;
      _completedOrders = completedOrders.length;
      _totalRevenue = revenue;
      _knownOrderIds
        ..clear()
        ..addAll(allOrders.map((order) => order.id));
    });
  }

  Future<void> _loadPartnerData({bool silent = false}) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null || !user.isPartner) return;

    final showBlockingLoader = !silent || !_hasLoadedOnce;
    if (showBlockingLoader) {
      setState(() => _isLoading = true);
    }
    try {
      Partner? nextPartner = _myPartner;
      try {
        nextPartner = await ApiService.getMyPartner();
      } catch (_) {}

      final allOrders =
          await ApiService.getDeliveryOrders(storeId: user.partnerId);
      if (!mounted) return;
      setState(() {
        _myPartner = nextPartner;
      });
      _syncFromOrderList(allOrders);
      if (showBlockingLoader) {
        setState(() => _isLoading = false);
      }
      _hasLoadedOnce = true;
    } catch (_) {
      if (mounted && showBlockingLoader) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _partnerStoresPrepaid {
    final m = _myPartner?.deliveryPaymentCollectionMode;
    if (m == null || m.isEmpty) return true;
    return m == 'prepaid';
  }

  String? get _billingTypeForPartnerInitiate {
    final m = _myPartner?.deliveryPaymentCollectionMode;
    if (m == 'postpaid_pix') return 'PIX';
    if (m == 'authorize_capture') return 'CREDIT_CARD';
    return null;
  }

  Future<void> _openPaymentCheckout(DeliveryOrder order) async {
    try {
      final payment = await ApiService.initiateDeliveryPayment(
        order.id,
        billingType: _billingTypeForPartnerInitiate,
      );
      final url = payment['invoiceUrl'] as String?;
      if (url == null || url.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link da cobrança indisponível. Tente de novo.'),
          ),
        );
        return;
      }
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link de pagamento.'),
          ),
        );
      }
      await _loadPartnerData(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar cobrança: $e')),
      );
    }
  }

  Future<void> _dispatchOrder(DeliveryOrder order) async {
    if (_dispatchingOrderIds.contains(order.id)) return;
    setState(() => _dispatchingOrderIds.add(order.id));
    try {
      await ApiService.dispatchOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido liberado. O app está notificando motociclistas na região.',
          ),
        ),
      );
      await _loadPartnerData(silent: true);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiStructuredException &&
          e.code == 'PAYMENT_REQUIRED_PREPAID') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            action: SnackBarAction(
              label: 'Cobrar',
              onPressed: () => _openPaymentCheckout(order),
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível chamar motociclista: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _dispatchingOrderIds.remove(order.id));
      }
    }
  }

  void _openCreateOrder() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    final userLat = user?.currentLat ?? -23.5505;
    final userLng = user?.currentLng ?? -46.6333;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateDeliveryModal(
        userLat: userLat,
        userLng: userLng,
        onOrderCreated: _loadPartnerData,
      ),
    ).then((_) => _loadPartnerData());
  }

  void _openOrderDetail(DeliveryOrder order) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    final userLat = user?.currentLat ?? -23.5505;
    final userLng = user?.currentLng ?? -46.6333;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
        builder: (context) => DeliveryDetailModal(
        order: order,
        userLat: userLat,
        userLng: userLng,
        partnerCollectionMode: _myPartner?.deliveryPaymentCollectionMode,
        onOrderUpdated: _loadPartnerData,
      ),
    ).then((_) => _loadPartnerData());
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);
    final storeName = appState.user?.name ?? 'Minha Loja';

    return Column(
      children: [
        ModernHeader(
          title: storeName,
          hideClockAndKm: true,
        ),
        Expanded(
          child: _isLoading && !_hasLoadedOnce
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: AppColors.racingOrange,
                  onRefresh: () => _loadPartnerData(silent: true),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildGreeting(theme, storeName),
                            const SizedBox(height: 20),
                            _buildQuickStats(theme, isDark),
                            const SizedBox(height: 16),
                            _buildRevenueCard(theme, isDark),
                            const SizedBox(height: 20),
                            _buildNewOrderCta(theme),
                            if (_activeOrders.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _sectionHeader(
                                theme,
                                title: 'Em andamento',
                                count: _activeOrders.length,
                                accent: AppColors.statusOk,
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DeliveryScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              ..._activeOrders.take(8).map(
                                    (o) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildOrderCard(
                                        theme,
                                        o,
                                        variant: _OrderCardVariant.active,
                                      ),
                                    ),
                                  ),
                            ],
                            if (_pendingOrders.isNotEmpty ||
                                _awaitingDispatchOrders.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _buildChamadosSection(theme, isDark),
                            ],
                            if (_activeOrders.isEmpty &&
                                _pendingOrders.isEmpty &&
                                _awaitingDispatchOrders.isEmpty) ...[
                              const SizedBox(height: 32),
                              _buildEmptyState(theme, isDark),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGreeting(ThemeData theme, String storeName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          storeName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Total',
            value: '$_totalOrders',
            icon: LucideIcons.package,
            color: AppColors.racingOrange,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Aguardando',
            value: '${_pendingOrders.length + _awaitingDispatchOrders.length}',
            icon: LucideIcons.clock,
            color: AppColors.statusWarning,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Ativos',
            value: '${_activeOrders.length}',
            icon: LucideIcons.truck,
            color: AppColors.statusOk,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.neonGreen.withValues(alpha: isDark ? 0.12 : 0.18),
            AppColors.neonGreen.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.35),
        ),
        boxShadow: AppColors.raisedPanelShadows(isDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.trendingUp,
              color: AppColors.neonGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receita de hoje',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(_totalRevenue),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.neonGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '$_completedOrders entregas concluídas no total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrderCta(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCreateOrder,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.racingOrange, AppColors.racingOrangeLight],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.racingOrange.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.plus, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Novo pedido',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Criar entrega e chamar motociclistas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme, {
    required String title,
    required int count,
    required Color accent,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'Ver todos',
              style: TextStyle(
                color: AppColors.racingOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChamadosSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          theme,
          title: 'Chamados',
          count: _pendingOrders.length + _awaitingDispatchOrders.length,
          accent: AppColors.statusWarning,
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'WhatsApp: inclua «Valor do item» no texto. Pedidos da loja: use «Confirmar e chamar».',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        ..._pendingOrders.take(6).map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderCard(
                  theme,
                  o,
                  variant: _OrderCardVariant.pending,
                  showMotoSearchBanner: true,
                ),
              ),
            ),
        ..._awaitingDispatchOrders.take(6).map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderCard(
                  theme,
                  o,
                  variant: _OrderCardVariant.awaitingDispatch,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.packageOpen,
            size: 48,
            color: AppColors.racingOrange.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum pedido no momento',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um novo pedido ou aguarde chamados pelo WhatsApp.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    ThemeData theme,
    DeliveryOrder order, {
    required _OrderCardVariant variant,
    bool showMotoSearchBanner = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final isDispatching = _dispatchingOrderIds.contains(order.id);
    final accent = switch (variant) {
      _OrderCardVariant.active => AppColors.statusOk,
      _OrderCardVariant.pending => AppColors.statusWarning,
      _OrderCardVariant.awaitingDispatch => AppColors.racingOrange,
    };
    final statusLabel = PartnerDeliveryStatusTracker.shortTitle(order.status);
    final hasRider = (order.riderName ?? '').isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: AppColors.raisedPanelShadows(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openOrderDetail(order),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            variant == _OrderCardVariant.active
                                ? LucideIcons.navigation
                                : LucideIcons.package,
                            color: accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.recipientName ?? 'Cliente',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.deliveryAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.7),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(order.totalValue),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.neonGreen,
                              ),
                            ),
                            if (order.value > 0)
                              Text(
                                'Itens ${_formatCurrency(order.value)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.55),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (showMotoSearchBanner) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.radio,
                            size: 14,
                            color: AppColors.statusOk,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Notificando motociclistas…',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.statusOk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (hasRider && variant == _OrderCardVariant.active)
            _buildRiderStrip(theme, order),
          if (!_partnerStoresPrepaid &&
              variant == _OrderCardVariant.active &&
              DeliveryStatusUtils.isActive(order.status))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openPaymentCheckout(order),
                  icon: const Icon(LucideIcons.smartphone, size: 17),
                  label: Text(
                    _myPartner?.deliveryPaymentCollectionMode == 'postpaid_pix'
                        ? 'PIX na corrida · cobrar agora'
                        : 'Gerar cobrança ao cliente',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        AppColors.statusOk.withValues(alpha: 0.95),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: AppColors.statusOk.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          if (variant == _OrderCardVariant.awaitingDispatch) ...[
            if (DeliveryStatusUtils.allowsStorePaymentCheckout(
              order.status,
              _myPartner?.deliveryPaymentCollectionMode,
            )) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openPaymentCheckout(order),
                    icon: const Icon(LucideIcons.banknote, size: 18),
                    label: Text(
                      _partnerStoresPrepaid
                          ? 'Gerar link de pagamento (PIX/cartão)'
                          : (_myPartner?.deliveryPaymentCollectionMode ==
                                  'postpaid_pix'
                              ? 'Gerar PIX antes de despachar (opcional)'
                              : 'Gerar cobrança ao cliente'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.racingOrange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: AppColors.racingOrange.withValues(alpha: 0.55),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isDispatching ? null : () => _dispatchOrder(order),
                  icon: isDispatching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.bike, size: 18),
                  label: Text(
                    isDispatching
                        ? 'Chamando motos…'
                        : 'Confirmar e chamar motociclista',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.racingOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => unawaited(_openDeliveryIssueReport(order)),
              icon: Icon(
                LucideIcons.flag,
                size: 15,
                color: theme.colorScheme.error.withValues(alpha: 0.85),
              ),
              label: const Text('Reportar'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderStrip(ThemeData theme, DeliveryOrder order) {
    final name = order.riderName ?? 'Entregador';
    final photoUrl = order.riderPhotoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Material(
      color: AppColors.racingOrange.withValues(alpha: 0.06),
      child: InkWell(
        onTap: () => PartnerRiderDetailSheet.show(context, order),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.racingOrange.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPhoto
                    ? ApiImage(url: photoUrl, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Toque para ver foto, moto e código',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.racingOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: AppColors.racingOrange.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OrderCardVariant { active, pending, awaitingDispatch }

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: AppColors.raisedPanelShadows(isDark),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
