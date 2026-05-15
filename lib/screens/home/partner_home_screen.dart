import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../models/delivery_order.dart';
import '../../utils/colors.dart';
import '../../utils/delivery_status_utils.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/api_image.dart';
import '../../widgets/partner_delivery_status_tracker.dart';
import '../delivery/create_delivery_modal.dart';
import '../delivery/delivery_detail_modal.dart';
import '../delivery/delivery_screen.dart';

/// Home do lojista (parceiro): dashboard com mapa, Novo Pedido, resumo e listas de pedidos.
class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  List<DeliveryOrder> _allOrders = [];
  List<DeliveryOrder> _activeOrders = [];
  List<DeliveryOrder> _awaitingDispatchOrders = [];
  List<DeliveryOrder> _pendingOrders = [];
  final Set<String> _dispatchingOrderIds = <String>{};
  final Set<String> _knownOrderIds = <String>{};
  final Set<String> _riderArrivedDialogOrderIds = <String>{};
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

    final orderRaw = payload['order'];
    if (orderRaw is Map<String, dynamic>) {
      try {
        final order = ApiService.deliveryOrderFromJson(
          Map<String, dynamic>.from(orderRaw),
        );
        if (order.storeId != partnerId) return;

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
      final theme = Theme.of(context);
      final bikeParts = <String>[
        if ((order.riderBikeModel ?? '').trim().isNotEmpty) order.riderBikeModel!.trim(),
        if ((order.riderBikePlate ?? '').trim().isNotEmpty) order.riderBikePlate!.trim(),
      ];
      final bikeLine = bikeParts.isEmpty ? 'Veículo não cadastrado no app.' : bikeParts.join(' · ');
      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              '${order.riderName ?? 'Motociclista'} chegou na loja',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.riderPhotoUrl != null && order.riderPhotoUrl!.isNotEmpty)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: ApiImage(url: order.riderPhotoUrl!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  if (order.riderPhotoUrl != null && order.riderPhotoUrl!.isNotEmpty)
                    const SizedBox(height: 12),
                  Text('Moto', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(bikeLine, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 14),
                  Text('Código para o entregador retirar o pedido', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    order.internalCode ?? '—',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.neonGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'São 4 dígitos — leia em voz alta ou mostre no ecrã.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
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
      final allOrders = await ApiService.getDeliveryOrders(storeId: user.partnerId);
      if (!mounted) return;
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

  Future<void> _dispatchOrder(DeliveryOrder order) async {
    if (_dispatchingOrderIds.contains(order.id)) return;
    setState(() => _dispatchingOrderIds.add(order.id));
    try {
      await ApiService.dispatchOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido liberado. O app esta notificando motociclistas na regiao.',
          ),
        ),
      );
      await _loadPartnerData(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel chamar motociclista: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _dispatchingOrderIds.remove(order.id));
      }
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
    final isDark = theme.brightness == Brightness.dark;
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.user;
    final userLat = user?.currentLat ?? -23.5505;
    final userLng = user?.currentLng ?? -46.6333;
    final mapMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('partner_store'),
        position: LatLng(userLat, userLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        ),
      ),
      ..._activeOrders
          .where((o) => o.deliveryLatitude != 0 && o.deliveryLongitude != 0)
          .take(20)
          .map(
            (o) => Marker(
              markerId: MarkerId('partner_delivery_${o.id}'),
              position: LatLng(o.deliveryLatitude, o.deliveryLongitude),
              infoWindow: InfoWindow(
                title: o.recipientName ?? 'Destino',
                snippet: o.internalCode ?? o.id.substring(0, 8),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.racingOrange.withOpacity(0.2)),
            boxShadow: AppColors.raisedPanelShadows(isDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(userLat, userLng),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: mapMarkers,
          ),
        ),
        const SizedBox(height: 20),
        _buildChamadosDeEntregaSection(theme),
        const SizedBox(height: 20),
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
              border: Border.all(color: Colors.white.withOpacity(0.22)),
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
                isDark: isDark,
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
                isDark: isDark,
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
                isDark: isDark,
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
            boxShadow: AppColors.raisedPanelShadows(isDark),
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
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildChamadosDeEntregaSection(ThemeData theme) {
    if (_pendingOrders.isEmpty && _awaitingDispatchOrders.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Chamados de entrega',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
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
                style: TextStyle(
                  color: AppColors.racingOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pedidos pelo WhatsApp entram já chamando motociclistas — não precisa de aprovação. '
          'Pedidos criados aqui na loja: use «Confirmar e chamar» para enviar aos motos.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.72),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        ..._pendingOrders.take(6).map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderCard(
                  context,
                  theme,
                  order,
                  isActive: false,
                  showDispatchButton: false,
                  showMotoSearchBanner: true,
                ),
              ),
            ),
        ..._awaitingDispatchOrders.take(6).map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderCard(
                  context,
                  theme,
                  order,
                  isActive: false,
                  showDispatchButton: true,
                  showMotoSearchBanner: false,
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
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
            isDark ? AppColors.panelDarkLow : AppColors.panelLightLow,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: AppColors.raisedPanelShadows(isDark),
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
    bool showDispatchButton = false,
    bool showMotoSearchBanner = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final isDispatching = _dispatchingOrderIds.contains(order.id);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    final userLat = user?.currentLat ?? -23.5505;
    final userLng = user?.currentLng ?? -46.6333;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
              isDark ? AppColors.panelDarkLow : AppColors.panelLightLow,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.statusOk.withOpacity(0.3)
                : AppColors.statusWarning.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: AppColors.raisedPanelShadows(isDark),
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
            const SizedBox(height: 10),
            PartnerDeliveryStatusTracker(status: order.status, compact: false),
            if (showMotoSearchBanner &&
                DeliveryStatusUtils.isPending(order.status)) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.bell, size: 14, color: AppColors.statusOk),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Motociclistas estão sendo notificados neste momento.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.statusOk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (isActive && order.riderName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.racingOrange.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.racingOrange.withOpacity(0.5)),
                          ),
                          child: ClipOval(
                            child: (order.riderPhotoUrl != null && order.riderPhotoUrl!.isNotEmpty)
                                ? ApiImage(url: order.riderPhotoUrl!, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      order.riderName![0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.riderName!,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (order.riderEmail != null && order.riderEmail!.isNotEmpty)
                                Text(
                                  order.riderEmail!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                                  ),
                                ),
                              if (order.riderPhone != null && order.riderPhone!.isNotEmpty)
                                Text(
                                  order.riderPhone!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                                  ),
                                ),
                              if ((order.riderBikeModel ?? '').isNotEmpty ||
                                  (order.riderBikePlate ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    [
                                      if ((order.riderBikeModel ?? '').isNotEmpty)
                                        order.riderBikeModel!,
                                      if ((order.riderBikePlate ?? '').isNotEmpty)
                                        order.riderBikePlate!,
                                    ].join(' · '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.racingOrange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (order.internalCode != null && order.internalCode!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(LucideIcons.hash, size: 14, color: AppColors.neonGreen),
                          const SizedBox(width: 6),
                          Text(
                            'Código para o entregador (4 dígitos): ${order.internalCode}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (showDispatchButton &&
                DeliveryStatusUtils.isAwaitingDispatch(order.status)) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isDispatching ? null : () => _dispatchOrder(order),
                  icon: isDispatching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.bike, size: 18),
                  label: Text(
                    isDispatching
                        ? 'Chamando motociclistas...'
                        : 'Confirmar e Chamar Motociclista',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.racingOrangeDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
        ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 2),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => unawaited(_openDeliveryIssueReport(order)),
              icon: Icon(LucideIcons.flag, size: 16, color: theme.colorScheme.error),
              label: const Text('Reportar problema'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ),
      ],
    );
  }
}
