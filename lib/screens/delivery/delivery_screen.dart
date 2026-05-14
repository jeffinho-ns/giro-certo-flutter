import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/delivery_order.dart';
import '../../models/partner.dart';
import '../../models/rider_stats.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/colors.dart';
import '../../features/trip_navigation/widgets/trip_delivery_proof_dialog.dart';
import '../../utils/delivery_constants.dart';
import '../../utils/delivery_proof_pin.dart';
import '../../utils/delivery_status_utils.dart';
import '../../models/vehicle_type.dart';
import '../../features/trip_navigation/trip_navigation_launcher.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/rider_dashboard.dart';
import 'delivery_order_card.dart';
import 'create_delivery_modal.dart';
import 'delivery_detail_modal.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

enum DeliveryMapInsightMode { demand, highPay, partnerDensity }

enum ZoneTimeWindow { now, lunchPeak, eveningPeak }

class _DeliveryScreenState extends State<DeliveryScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  GoogleMapController? _mapController;
  Timer? _marketPulseTimer;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliveryRealtimeSubscription;
  Timer? _realtimeReloadDebounce;

  // Localização real do usuário (fallback inicial em São Paulo)
  double _userLatitude = -23.5505;
  double _userLongitude = -46.6333;

  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _loadError;
  List<DeliveryOrder> _orders = [];
  List<DeliveryOrder> _myOrders = []; // Corridas aceitas pelo usuário
  List<DeliveryOrder> _completedOrders = []; // Corridas concluídas
  List<Partner> _partners = [];
  RiderStats? _riderStats;
  DeliveryMapInsightMode _mapInsightMode = DeliveryMapInsightMode.demand;
  ZoneTimeWindow _timeWindow = ZoneTimeWindow.now;
  bool _showOrderPins = true;
  bool _showPartnerPins = true;

  // Determina se é motociclista ou lojista baseado no usuário logado
  bool get _isRiderMode {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    return appState.user?.isRider ?? true; // Default para motociclista
  }

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _requestLocationAndListen();
    _subscribeDeliveryRealtime();
    _loadOrders();
    _marketPulseTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _loadOrders(silent: true);
    });
  }

  void _initializeTabController() {
    _tabController?.dispose();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isRider = appState.user?.isRider ?? true;

    _tabController = TabController(
      length: isRider ? 3 : 2,
      vsync: this,
      initialIndex: 0,
    );
  }

  @override
  void dispose() {
    _marketPulseTimer?.cancel();
    _positionSubscription?.cancel();
    _deliveryRealtimeSubscription?.cancel();
    _realtimeReloadDebounce?.cancel();
    _tabController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocationAndListen() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _userLatitude = initial.latitude;
        _userLongitude = initial.longitude;
      });

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() {
          _userLatitude = pos.latitude;
          _userLongitude = pos.longitude;
        });
        final activeOrder = _myOrders.isNotEmpty ? _myOrders.first : null;
        RealtimeService.instance.emitRiderLocationThrottled(
          lat: pos.latitude,
          lng: pos.longitude,
          orderId: activeOrder?.id,
          orderStatus: activeOrder?.status.name,
        );
      });
    } catch (_) {}
  }

  void _subscribeDeliveryRealtime() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userId = appState.user?.id;
    if (userId == null) return;
    RealtimeService.instance.connect(userId);
    _deliveryRealtimeSubscription =
        RealtimeService.instance.onDeliveryStatusChanged.listen((_) {
      _realtimeReloadDebounce?.cancel();
      _realtimeReloadDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _loadOrders(silent: true);
      });
    });
  }

  Future<void> _loadOrders({bool silent = false}) async {
    final shouldShowBlockingLoader = !silent || !_hasLoadedOnce;
    if (shouldShowBlockingLoader) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    } else {
      setState(() {
        _loadError = null;
      });
    }

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final user = appState.user;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'Sessao expirada. Faca login novamente.';
        });
        return;
      }

      // Integrar com API real
      if (_isRiderMode) {
        // Motociclista: pedidos pendentes + minhas corridas
        final results = await Future.wait([
          ApiService.getDeliveryOrders(
            status: 'pending',
            limit: 60,
            hidePickupCode: true,
          ),
          ApiService.getDeliveryOrders(riderId: user.id, hidePickupCode: true),
          ApiService.getPartners(),
        ]);
        final allOrders = results[0] as List<DeliveryOrder>;
        final myOrders = results[1] as List<DeliveryOrder>;
        final partners = results[2] as List<Partner>;

        setState(() {
          _orders = allOrders
              .where((o) => DeliveryStatusUtils.isPending(o.status))
              .toList();
          _myOrders = myOrders
              .where((o) => DeliveryStatusUtils.isActive(o.status))
              .toList();
          _completedOrders = myOrders
              .where((o) => DeliveryStatusUtils.isCompleted(o.status))
              .toList();
          _partners = partners;
          _riderStats = RiderStats.fromOrders(_completedOrders);
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      } else {
        // Lojista: buscar apenas seus próprios pedidos
        if (user.partnerId != null) {
          final results = await Future.wait([
            ApiService.getDeliveryOrders(storeId: user.partnerId),
            ApiService.getPartners(),
          ]);
          final myOrders = results[0] as List<DeliveryOrder>;
          final partners = results[1] as List<Partner>;

          setState(() {
            _orders = myOrders
                .where((o) => DeliveryStatusUtils.isPending(o.status))
                .toList();
            _myOrders = myOrders
                .where((o) => DeliveryStatusUtils.isActive(o.status))
                .toList();
            _completedOrders = myOrders
                .where((o) => DeliveryStatusUtils.isCompleted(o.status))
                .toList();
            _partners = partners;
            _isLoading = false;
            _hasLoadedOnce = true;
          });
        } else {
          setState(() {
            _orders = [];
            _myOrders = [];
            _completedOrders = [];
            _partners = [];
            _isLoading = false;
            _hasLoadedOnce = true;
          });
        }
      }
    } catch (e) {
      final message = 'Erro ao carregar pedidos: $e';
      if (mounted) {
        setState(() {
          _loadError = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (shouldShowBlockingLoader) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _acceptOrder(DeliveryOrder order) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null) return;

    try {
      final completed = await TripNavigationLauncher.acceptAndOpen(
        context,
        order: order,
        riderId: user.id,
        riderName: user.name,
      );

      if (!mounted) return;

      setState(() {
        _orders.removeWhere((o) => o.id == order.id);
        _myOrders.removeWhere((o) => o.id == order.id);
        _updateStats();
      });

      if (completed == true) {
        await _loadOrders(silent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aceitar corrida: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateStats() {
    if (_isRiderMode) {
      final allOrders = [..._orders, ..._completedOrders];
      _riderStats = RiderStats.fromOrders(allOrders);
    }
  }

  Future<void> _completeOrder(DeliveryOrder order) async {
    final pin = await showTripDeliveryProofDialog(context);
    if (pin == null || !DeliveryProofPin.isValidFormat(pin)) return;

    try {
      final updatedOrder = await ApiService.completeOrder(
        order.id,
        deliveryPin: pin,
      );

      setState(() {
        _orders.removeWhere((o) => o.id == order.id);
        _myOrders.removeWhere((o) => o.id == order.id);
        _completedOrders.insert(0, updatedOrder);

        // Atualizar estatísticas
        _updateStats();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Corrida concluída! Ganhos: R\$ ${order.deliveryFee.toStringAsFixed(2)}'),
            backgroundColor: AppColors.neonGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao concluir corrida: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    final pendingOrders =
        _orders.where((o) => DeliveryStatusUtils.isPending(o.status)).toList();

    return Scaffold(
      body: Column(
        children: [
          ModernHeader(
            title: _isRiderMode ? 'Corridas' : 'Meus Pedidos',
            showBackButton: true,
            onBackPressed: () => Navigator.of(context).maybePop(),
          ),

          // Tabs - Verificar que TabController existe e tem o tamanho correto
          if (_tabController != null &&
              _tabController!.length == (_isRiderMode ? 3 : 2))
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
                    isDark ? AppColors.panelDarkLow : AppColors.panelLightLow,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
                boxShadow: AppColors.raisedPanelShadows(isDark),
              ),
              child: TabBar(
                controller: _tabController!,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.racingOrangeLight.withOpacity(0.9),
                      AppColors.racingOrangeDark.withOpacity(0.9),
                    ],
                  ),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor:
                    theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
                tabs: _isRiderMode
                    ? const [
                        Tab(icon: Icon(LucideIcons.map), text: 'Mapa'),
                        Tab(icon: Icon(LucideIcons.list), text: 'Disponíveis'),
                        Tab(
                            icon: Icon(LucideIcons.package),
                            text: 'Minhas Corridas'),
                      ]
                    : const [
                        Tab(icon: Icon(LucideIcons.map), text: 'Áreas Quentes'),
                        Tab(icon: Icon(LucideIcons.list), text: 'Meus Pedidos'),
                      ],
              ),
            )
          else
            SizedBox(
                height:
                    48), // Placeholder enquanto TabController não está pronto

          // Conteúdo - Verificar que TabController existe e tem o tamanho correto
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  )
                : _loadError != null
                    ? _buildLoadErrorState(theme, primaryColor)
                    : _tabController != null &&
                            _tabController!.length == (_isRiderMode ? 3 : 2)
                        ? Stack(
                            children: [
                              TabBarView(
                                controller: _tabController!,
                                children: _isRiderMode
                                    ? [
                                        _buildMapView(
                                            theme, pendingOrders, primaryColor),
                                        _buildRiderOrdersList(
                                            theme, pendingOrders, primaryColor),
                                        _buildMyDeliveriesView(theme),
                                      ]
                                    : [
                                        _buildMapView(
                                            theme, pendingOrders, primaryColor),
                                        _buildStoreOrdersList(theme),
                                      ],
                              ),
                              // Botão flutuante de criar pedido (apenas para lojista)
                              if (!_isRiderMode)
                                Positioned(
                                  bottom: 90, // Acima do menu inferior
                                  right: 16,
                                  child: FloatingActionButton.extended(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            CreateDeliveryModal(
                                          userLat: _userLatitude,
                                          userLng: _userLongitude,
                                          onOrderCreated: () {
                                            _loadOrders();
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    },
                                    backgroundColor: AppColors.racingOrangeDark,
                                    icon: const Icon(LucideIcons.plus,
                                        color: Colors.white),
                                    label: const Text(
                                      'Criar Pedido',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadErrorState(ThemeData theme, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: 56,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Nao foi possivel carregar os pedidos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Falha de conexao.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderRadiusBanner(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
  ) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isBike = appState.bike?.vehicleType == AppVehicleType.bicycle;
    if (!_isRiderMode) return const SizedBox.shrink();
    return Material(
      color: primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.info, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DeliveryMatchRules.radiusMessage(isBicycle: isBike),
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(
      ThemeData theme, List<DeliveryOrder> orders, Color primaryColor) {
    final userLocation = LatLng(_userLatitude, _userLongitude);
    final hotZones = _buildHotZones(orders, _partners);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Sua localização'),
      ),
      ...hotZones.map((zone) {
        final zonePoint =
            LatLng(zone['latitude'] as double, zone['longitude'] as double);
        final label = zone['label'] as String;
        return Marker(
          markerId: MarkerId('hot_zone_$label'),
          position: zonePoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: 'Zona quente', snippet: label),
        );
      }),
      ...(_showOrderPins ? orders : <DeliveryOrder>[]).expand((order) => [
            Marker(
              markerId: MarkerId('order_store_${order.id}'),
              position: LatLng(order.storeLatitude, order.storeLongitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              onTap: () => _showOrderDetail(order),
              infoWindow: InfoWindow(
                title: 'Loja',
                snippet: order.storeName,
              ),
            ),
            Marker(
              markerId: MarkerId('order_delivery_${order.id}'),
              position: LatLng(order.deliveryLatitude, order.deliveryLongitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              onTap: () => _showOrderDetail(order),
              infoWindow: InfoWindow(
                title: 'Entrega',
                snippet: order.deliveryAddress,
              ),
            ),
          ]),
      ...(_showPartnerPins ? _partners : <Partner>[]).map(
        (partner) => Marker(
          markerId: MarkerId('partner_${partner.id}'),
          position: LatLng(partner.latitude, partner.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            partner.type == PartnerType.store
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueCyan,
          ),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${partner.name} • ${partner.address}'),
              duration: const Duration(seconds: 2),
            ),
          ),
          infoWindow: InfoWindow(title: partner.name),
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRiderRadiusBanner(context, theme, primaryColor),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: userLocation,
                  zoom: 13.0,
                ),
                onMapCreated: (controller) => _mapController = controller,
                mapType: MapType.normal,
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                right: 10,
                top: 10,
                child: _buildMapInsightsPanel(theme, primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapInsightsPanel(ThemeData theme, Color primaryColor) {
    final isDark = theme.brightness == Brightness.dark;
    Widget modeChip(DeliveryMapInsightMode mode, String label) {
      final selected = _mapInsightMode == mode;
      return ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => setState(() => _mapInsightMode = mode),
        selectedColor: primaryColor.withOpacity(0.22),
        side: BorderSide(color: theme.dividerColor),
      );
    }

    return Container(
      width: 230,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppColors.panelDarkHigh.withOpacity(0.95)
                : AppColors.panelLightHigh.withOpacity(0.98),
            isDark
                ? AppColors.panelDarkLow.withOpacity(0.9)
                : AppColors.panelLightLow.withOpacity(0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.racingOrange.withOpacity(0.2)),
        boxShadow: AppColors.raisedPanelShadows(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mapa Dinâmico',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              modeChip(DeliveryMapInsightMode.demand, 'Mais corridas'),
              modeChip(DeliveryMapInsightMode.highPay, 'Melhor pagamento'),
              modeChip(DeliveryMapInsightMode.partnerDensity, 'Mais parceiros'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _timeChip(theme, ZoneTimeWindow.now, 'Agora'),
              _timeChip(theme, ZoneTimeWindow.lunchPeak, 'Pico almoço'),
              _timeChip(theme, ZoneTimeWindow.eveningPeak, 'Pico noite'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FilterChip(
                label: const Text('Pedidos', style: TextStyle(fontSize: 11)),
                selected: _showOrderPins,
                onSelected: (v) => setState(() => _showOrderPins = v),
              ),
              FilterChip(
                label: const Text('Parceiros', style: TextStyle(fontSize: 11)),
                selected: _showPartnerPins,
                onSelected: (v) => setState(() => _showPartnerPins = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildZoneRankingPreview(theme),
        ],
      ),
    );
  }

  Widget _timeChip(ThemeData theme, ZoneTimeWindow value, String label) {
    final selected = _timeWindow == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => setState(() => _timeWindow = value),
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
    );
  }

  List<Map<String, dynamic>> _buildHotZones(
    List<DeliveryOrder> orders,
    List<Partner> partners,
  ) {
    if (orders.isEmpty && partners.isEmpty) return const [];
    final Map<String, Map<String, dynamic>> buckets = {};
    String keyFor(double lat, double lng) =>
        '${(lat * 50).round() / 50}_${(lng * 50).round() / 50}';

    for (final order in orders) {
      final hourBoost = _hourWeight(order.createdAt.hour);
      final key = keyFor(order.storeLatitude, order.storeLongitude);
      final b = buckets.putIfAbsent(
        key,
        () => {
          'latitude': order.storeLatitude,
          'longitude': order.storeLongitude,
          'orders': 0,
          'weightedOrders': 0.0,
          'pay': 0.0,
          'partners': 0,
        },
      );
      b['orders'] = (b['orders'] as int) + 1;
      b['weightedOrders'] = (b['weightedOrders'] as double) + hourBoost;
      b['pay'] = (b['pay'] as double) + order.deliveryFee;
    }
    for (final partner in partners) {
      final key = keyFor(partner.latitude, partner.longitude);
      final b = buckets.putIfAbsent(
        key,
        () => {
          'latitude': partner.latitude,
          'longitude': partner.longitude,
          'orders': 0,
          'weightedOrders': 0.0,
          'pay': 0.0,
          'partners': 0,
        },
      );
      b['partners'] = (b['partners'] as int) + 1;
    }

    final zones = buckets.values.toList();
    zones.sort((a, b) {
      double score(Map<String, dynamic> z) {
        final ordersScore = (z['weightedOrders'] as double);
        final partnersScore = (z['partners'] as int).toDouble();
        final avgPay =
            ordersScore > 0 ? (z['pay'] as double) / ordersScore : 0.0;
        switch (_mapInsightMode) {
          case DeliveryMapInsightMode.demand:
            return ordersScore * 2 + partnersScore;
          case DeliveryMapInsightMode.highPay:
            return avgPay + ordersScore * 0.25;
          case DeliveryMapInsightMode.partnerDensity:
            return partnersScore * 2 + ordersScore;
        }
      }

      return score(b).compareTo(score(a));
    });

    return zones.take(12).map((z) {
      final ordersCount = z['orders'] as int;
      final weightedOrders = z['weightedOrders'] as double;
      final partnersCount = z['partners'] as int;
      final avgPay = ordersCount > 0 ? (z['pay'] as double) / ordersCount : 0.0;
      String label;
      int level;
      switch (_mapInsightMode) {
        case DeliveryMapInsightMode.demand:
          label = weightedOrders.toStringAsFixed(1);
          level = weightedOrders.round().clamp(1, 7);
          break;
        case DeliveryMapInsightMode.highPay:
          label = 'R\$${avgPay.toStringAsFixed(0)}';
          level = ((avgPay / 4).round()).clamp(1, 7);
          break;
        case DeliveryMapInsightMode.partnerDensity:
          label = '$partnersCount';
          level = partnersCount.clamp(1, 7);
          break;
      }
      return {
        ...z,
        'rawOrders': ordersCount,
        'label': label,
        'level': level,
      };
    }).toList();
  }

  double _hourWeight(int hour) {
    switch (_timeWindow) {
      case ZoneTimeWindow.now:
        final now = DateTime.now().hour;
        final distance = (hour - now).abs();
        if (distance == 0) return 2.0;
        if (distance <= 1) return 1.4;
        if (distance <= 2) return 1.1;
        return 0.8;
      case ZoneTimeWindow.lunchPeak:
        return (hour >= 11 && hour <= 14) ? 1.9 : 0.9;
      case ZoneTimeWindow.eveningPeak:
        return (hour >= 18 && hour <= 22) ? 2.0 : 0.85;
    }
  }

  List<Widget> _buildZoneRankingPreview(ThemeData theme) {
    final zones = _buildHotZones(_orders, _partners).take(4).toList();
    if (zones.isEmpty) {
      return [
        Text(
          'Sem dados para ranking no momento.',
          style: theme.textTheme.bodySmall,
        ),
      ];
    }

    final title = switch (_timeWindow) {
      ZoneTimeWindow.now => 'Ranking por horário: agora',
      ZoneTimeWindow.lunchPeak => 'Ranking por horário: almoço',
      ZoneTimeWindow.eveningPeak => 'Ranking por horário: noite',
    };

    return [
      Text(
        title,
        style:
            theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      ...zones.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final z = entry.value;
        final rawOrders = z['rawOrders'] as int? ?? 0;
        final partners = z['partners'] as int? ?? 0;
        final avgPay = rawOrders > 0 ? ((z['pay'] as double) / rawOrders) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '$idxº zona • corridas: $rawOrders • parceiros: $partners • ticket: R\$${avgPay.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        );
      }),
    ];
  }

  Widget _buildRiderOrdersList(
      ThemeData theme, List<DeliveryOrder> orders, Color primaryColor) {
    if (orders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRiderRadiusBanner(context, theme, primaryColor),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.package,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma corrida disponível',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Ordenar por prioridade e distância
    final sortedOrders = List<DeliveryOrder>.from(orders);
    sortedOrders.sort((a, b) {
      final priorityOrder = {
        DeliveryPriority.urgent: 0,
        DeliveryPriority.high: 1,
        DeliveryPriority.normal: 2,
        DeliveryPriority.low: 3,
      };
      final priorityDiff =
          priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      if (priorityDiff != 0) return priorityDiff;
      return (a.distance ?? 0).compareTo(b.distance ?? 0);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRiderRadiusBanner(context, theme, primaryColor),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) {
              final order = sortedOrders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeliveryOrderCard(
                  order: order,
                  userLat: _userLatitude,
                  userLng: _userLongitude,
                  onTap: () => _showOrderDetail(order),
                  onAccept: () => _acceptOrder(order),
                  showAcceptButton: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreOrdersList(ThemeData theme) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final partnerId = appState.user?.partnerId;

    // Filtrar apenas pedidos do parceiro logado
    final myStoreOrders = partnerId != null
        ? _orders.where((o) => o.storeId == partnerId).toList()
        : _orders; // Fallback: mostrar todos se não houver partnerId

    if (myStoreOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shoppingBag,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum pedido criado ainda',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + para criar um novo pedido',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myStoreOrders.length,
      itemBuilder: (context, index) {
        final order = myStoreOrders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DeliveryOrderCard(
            order: order,
            userLat: _userLatitude,
            userLng: _userLongitude,
            onTap: () => _showOrderDetail(order),
            showAcceptButton: false,
          ),
        );
      },
    );
  }

  Widget _buildMyDeliveriesView(ThemeData theme) {
    if (_riderStats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.package,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Carregando suas estatísticas...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Se não há corridas ativas nem histórico, mostrar mensagem
    if (_myOrders.isEmpty && _completedOrders.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Dashboard de ganhos
            RiderDashboard(stats: _riderStats!),
            const SizedBox(height: 40),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.package,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma corrida ainda',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aceite corridas para começar a ganhar!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    // Usar ListView customizado para evitar overflow
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Dashboard de ganhos
        RiderDashboard(stats: _riderStats!),

        // Corridas ativas
        if (_myOrders.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Corridas Ativas (${_myOrders.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ..._myOrders.map((order) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    DeliveryOrderCard(
                      order: order,
                      userLat: _userLatitude,
                      userLng: _userLongitude,
                      onTap: () => _showOrderDetail(order),
                      showAcceptButton: false,
                    ),
                    const SizedBox(height: 8),
                    _buildRiderStageAction(theme, order),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Histórico de corridas concluídas
        if (_completedOrders.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histórico de Corridas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_completedOrders.length} concluídas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ...(_completedOrders.length > 10
                  ? _completedOrders.take(10)
                  : _completedOrders)
              .map((order) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.neonGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.check,
                              color: AppColors.neonGreen,
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
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Concluída ${_formatDate(order.completedAt ?? order.createdAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'R\$ ${order.deliveryFee.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildRiderStageAction(ThemeData theme, DeliveryOrder order) {
    if (!DeliveryStatusUtils.isActive(order.status)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          unawaited(TripNavigationLauncher.open(context, order));
        },
        icon: const Icon(LucideIcons.navigation, size: 16),
        label: const Text('Continuar corrida'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.racingOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateDay == yesterday) {
      return 'ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showOrderDetail(DeliveryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryDetailModal(
        order: order,
        userLat: _userLatitude,
        userLng: _userLongitude,
        onAccept: () {
          Navigator.pop(context);
          _acceptOrder(order);
        },
        onComplete: () {
          Navigator.pop(context);
          _completeOrder(order);
        },
        isRider: _isRiderMode,
        showRouteHistory: !_isRiderMode,
      ),
    );
  }
}
