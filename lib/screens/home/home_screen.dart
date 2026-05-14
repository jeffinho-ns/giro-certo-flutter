import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/notifications_count_provider.dart';
import '../../providers/rider_delivery_session_provider.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/notification_service.dart';
import '../../models/delivery_order.dart';
import '../../models/partner.dart';
import '../../models/pilot_profile.dart';
import '../../utils/colors.dart';
import '../../utils/delivery_status_utils.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/quick_messages_card.dart';
import '../../widgets/home_map_fab_column.dart';
import '../maintenance/maintenance_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _googleMapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _marketCircles = {};
  LatLng? _currentPosition;
  bool _isLoading = false;
  bool _hasLoadedPartnerOnce = false;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliveryStatusSubscription;
  Timer? _realtimePartnerReloadDebounce;
  Timer? _deliveryPresenceSyncDebounce;
  DateTime? _lastDeliveryPresenceSyncAt;
  bool _heatmapOn = false;
  Set<MapFilterOption> _filterOptions = {};
  MapTimeWindowOption _mapTimeWindow = MapTimeWindowOption.now;
  List<QuickMessageItem> _quickMessages = [];
  List<DeliveryOrder> _marketPendingOrders = [];
  List<Partner> _marketPartners = [];
  MapType _mapType = MapType.normal;
  double _currentZoom = 15.0;

  static const LatLng _defaultCenter = LatLng(-23.5505, -46.6333);

  @override
  void initState() {
    super.initState();
    _loadQuickMessages();
    _requestLocationAndListen();
    _loadPartnerData();
    _loadMarketIntelligenceData();
    _subscribePartnerRealtimeUpdates();
    _syncDeliveryModerationStatus();
    _startDeliveryModerationSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final p =
            Provider.of<NotificationsCountProvider>(context, listen: false);
        p.loadFromApi();
        p.subscribeToRealtime();
      } catch (e) {
        debugPrint('Falha ao iniciar notificacoes em tempo real: $e');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Atualizar estilo do mapa quando o tema mudar
    _updateMapStyle();
  }

  Future<void> _updateMapStyle() async {
    final controller = _googleMapController;
    if (controller == null) return;
    final brightness = Theme.of(context).brightness;
    await controller.setMapStyle(
      brightness == Brightness.dark ? _darkMapStyle : _lightMapStyle,
    );
  }

  Future<void> _loadQuickMessages() async {
    try {
      final alerts = await ApiService.getAlerts(limit: 5);
      if (!mounted) return;
      setState(() {
        _quickMessages = alerts.map((a) {
          final title = a['title'] as String? ?? 'Alerta';
          final body = a['body'] as String?;
          final severity = (a['severity'] as String?)?.toLowerCase();
          IconData icon = LucideIcons.bell;
          Color? color = AppColors.racingOrange;
          if (severity == 'critical' || severity == 'high') {
            icon = LucideIcons.alertTriangle;
            color = AppColors.alertRed;
          } else if (severity == 'info') {
            icon = LucideIcons.info;
          }
          return QuickMessageItem(
              icon: icon, color: color, title: title, subtitle: body);
        }).toList();
      });
    } catch (e) {
      debugPrint('Falha ao carregar mensagens rapidas: $e');
      setState(() {
        _quickMessages = [
          const QuickMessageItem(
              icon: LucideIcons.checkCircle,
              color: AppColors.statusOk,
              title: 'Sistema ativo',
              subtitle: 'Sem alertas recentes'),
        ];
      });
    }
  }

  Future<void> _requestLocationAndListen() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
      _updateUserLocation(
        pos.latitude,
        pos.longitude,
      );
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((Position pos) {
        if (!mounted) return;
          setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          });
        _updateUserLocation(
          pos.latitude,
          pos.longitude,
          );
      });
    } catch (e) {
      debugPrint('Falha ao obter localizacao atual: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nao foi possivel obter sua localizacao. Exibindo uma localizacao padrao.',
            ),
          ),
        );
      }
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final user = appState.user;
      if (user?.currentLat != null && user?.currentLng != null) {
        setState(() {
          _currentPosition = LatLng(user!.currentLat!, user.currentLng!);
        });
      } else {
        setState(() => _currentPosition = _defaultCenter);
      }
    }
  }

  /// Torre de Controle: apenas Socket.io com throttle (~4 s). Sem PUT a cada GPS.
  void _updateUserLocation(
    double lat,
    double lng, {
    DeliveryOrder? activeOrder,
  }) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user != null) {
      appState.setUser(user.copyWith(currentLat: lat, currentLng: lng));
    }
    RealtimeService.instance.emitRiderLocationThrottled(
      lat: lat,
      lng: lng,
      orderId: activeOrder?.id,
      orderStatus: activeOrder != null ? activeOrder.status.name : null,
    );
    if (appState.isDeliveryPilot) {
      _scheduleDeliveryPresenceSync(lat, lng);
    }
  }

  void _scheduleDeliveryPresenceSync(double lat, double lng) {
    final lastSync = _lastDeliveryPresenceSyncAt;
    if (lastSync != null &&
        DateTime.now().difference(lastSync) < const Duration(seconds: 20)) {
      return;
    }
    _deliveryPresenceSyncDebounce?.cancel();
    _deliveryPresenceSyncDebounce = Timer(
      const Duration(milliseconds: 400),
      () async {
        _lastDeliveryPresenceSyncAt = DateTime.now();
        try {
          await ApiService.updateUserLocation(
            latitude: lat,
            longitude: lng,
            isOnline: true,
          );
        } catch (e) {
          debugPrint('Falha ao sincronizar presenca do entregador: $e');
        }
      },
    );
  }

  Future<void> _startDeliveryModerationSync() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.user?.isRider != true) return;
    while (mounted) {
      await _syncDeliveryModerationStatus();
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 60));
    }
  }

  Future<void> _syncDeliveryModerationStatus() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (!appState.isDeliveryPilot) return;

    try {
      final reg = await ApiService.getDeliveryRegistrationStatus();
      if (!mounted) return;
      final rawStatus = (reg?['status'] as String?)?.toUpperCase() ?? '';
      final previous = (await OnboardingService.getLastKnownDeliveryRegStatus())
              ?.toUpperCase() ??
          '';

      final nextStatus =
          DeliveryModerationStatusExtension.fromRegistrationApiStatus(
        reg?['status'] as String?,
      );

      final justApproved = rawStatus == 'APPROVED' &&
          previous != 'APPROVED' &&
          (previous == 'PENDING' ||
              previous == 'UNDER_REVIEW' ||
              previous.isEmpty);

      if (justApproved) {
        await showLocalNotification(
          id: 91001,
          title: 'Cadastro aprovado',
          body: 'Pode aceitar corridas de delivery. Boa jornada!',
          payload: 'notification',
        );
        try {
          final fresh = await ApiService.getCurrentUser();
          if (mounted) {
            appState.setUser(fresh);
          }
        } catch (e) {
          debugPrint('Falha ao atualizar utilizador após aprovação: $e');
        }
      }

      await OnboardingService.saveDeliveryStatus(nextStatus);

      if (appState.deliveryModerationStatus != nextStatus) {
        appState.setDeliveryModerationStatus(nextStatus);
      }

      if (appState.isDeliveryPilot &&
          appState.deliveryModerationStatus != DeliveryModerationStatus.approved &&
          mounted) {
        context.read<RiderDeliverySessionProvider>().dismissOffer();
      }

      await OnboardingService.setLastKnownDeliveryRegStatus(
        rawStatus.isEmpty ? null : rawStatus,
      );
    } catch (e) {
      debugPrint('Falha ao sincronizar aprovacao de delivery: $e');
    }
  }

  @override
  void dispose() {
    RealtimeService.instance.setNavigationMode(false);
    _positionSubscription?.cancel();
    _deliveryStatusSubscription?.cancel();
    _realtimePartnerReloadDebounce?.cancel();
    _deliveryPresenceSyncDebounce?.cancel();
    super.dispose();
  }

  void _subscribePartnerRealtimeUpdates() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userId = appState.user?.id;
    if (userId == null) return;
    if (appState.user?.isPartner != true) return;
    RealtimeService.instance.connect(userId);
    _deliveryStatusSubscription =
        RealtimeService.instance.onDeliveryStatusChanged.listen((_) {
      _realtimePartnerReloadDebounce?.cancel();
      _realtimePartnerReloadDebounce =
          Timer(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        _loadPartnerData(silent: true);
      });
    });
  }

  Future<void> _loadPartnerData({bool silent = false}) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null || !user.isPartner) return;

    final shouldShowBlockingLoader = !silent || !_hasLoadedPartnerOnce;
    if (shouldShowBlockingLoader) {
      setState(() => _isLoading = true);
    }
    try {
      await ApiService.getDeliveryOrders(storeId: user.partnerId);
      if (!mounted) return;
      if (shouldShowBlockingLoader) {
        setState(() => _isLoading = false);
      }
      _hasLoadedPartnerOnce = true;
    } catch (e) {
      debugPrint('Falha ao carregar dados do parceiro: $e');
      if (mounted && shouldShowBlockingLoader) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMarketIntelligenceData() async {
    try {
      final results = await Future.wait([
        ApiService.getDeliveryOrders(),
        ApiService.getPartners(),
      ]);
      if (!mounted) return;
      setState(() {
        _marketPendingOrders = (results[0] as List<DeliveryOrder>)
            .where((o) => DeliveryStatusUtils.isPending(o.status))
            .toList();
        _marketPartners = results[1] as List<Partner>;
      });
      _refreshMarketIntelligenceOverlays();
    } catch (e) {
      debugPrint('Falha ao carregar inteligencia do mapa: $e');
    }
  }

  void _refreshMarketIntelligenceOverlays() {
    final showHotOrders =
        _filterOptions.contains(MapFilterOption.hotOrders) || _heatmapOn;
    final showHighPay =
        _filterOptions.contains(MapFilterOption.highPay) || _heatmapOn;
    final showPartnerDensity =
        _filterOptions.contains(MapFilterOption.partnerDensity) || _heatmapOn;
    final showPartners = _filterOptions.contains(MapFilterOption.autoParts) ||
        _filterOptions.contains(MapFilterOption.mechanics) ||
        _filterOptions.contains(MapFilterOption.partnerDensity) ||
        _filterOptions.isEmpty;

    final markers = <Marker>{};
    final circles = <Circle>{};

    if (showPartners) {
      for (final p in _marketPartners.take(120)) {
        markers.add(
          Marker(
            markerId: MarkerId('partner_${p.id}'),
            position: LatLng(p.latitude, p.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              p.type == PartnerType.store
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(title: p.name, snippet: p.address),
          ),
        );
      }
    }

    final grouped = <String, Map<String, dynamic>>{};
    String keyFor(double lat, double lng) =>
        '${(lat * 50).round() / 50}_${(lng * 50).round() / 50}';

    for (final o in _marketPendingOrders) {
      final hourWeight = _timeWindowWeight(o.createdAt.hour);
      final k = keyFor(o.storeLatitude, o.storeLongitude);
      final g = grouped.putIfAbsent(
        k,
        () => {
          'lat': o.storeLatitude,
          'lng': o.storeLongitude,
          'orders': 0,
          'weightedOrders': 0.0,
          'pay': 0.0,
          'partners': 0,
        },
      );
      g['orders'] = (g['orders'] as int) + 1;
      g['weightedOrders'] = (g['weightedOrders'] as double) + hourWeight;
      g['pay'] = (g['pay'] as double) + o.deliveryFee;
    }
    for (final p in _marketPartners) {
      final k = keyFor(p.latitude, p.longitude);
      final g = grouped.putIfAbsent(
        k,
        () => {
          'lat': p.latitude,
          'lng': p.longitude,
          'orders': 0,
          'weightedOrders': 0.0,
          'pay': 0.0,
          'partners': 0,
        },
      );
      g['partners'] = (g['partners'] as int) + 1;
    }

    final topZones = grouped.values.toList()
      ..sort((a, b) {
        final aOrders = a['weightedOrders'] as double;
        final bOrders = b['weightedOrders'] as double;
        final aPartners = a['partners'] as int;
        final bPartners = b['partners'] as int;
        final aAvgPay = aOrders > 0 ? (a['pay'] as double) / aOrders : 0.0;
        final bAvgPay = bOrders > 0 ? (b['pay'] as double) / bOrders : 0.0;
        final aScore = (showHotOrders ? aOrders * 2.0 : 0.0) +
            (showPartnerDensity ? aPartners * 2 : 0) +
            (showHighPay ? aAvgPay : 0);
        final bScore = (showHotOrders ? bOrders * 2.0 : 0.0) +
            (showPartnerDensity ? bPartners * 2 : 0) +
            (showHighPay ? bAvgPay : 0);
        return bScore.compareTo(aScore);
      });

    for (final z in topZones.take(10)) {
      final orders = z['orders'] as int;
      final partners = z['partners'] as int;
      final avgPay = orders > 0 ? (z['pay'] as double) / orders : 0.0;
      final intensity =
          ((orders * 0.6) + (partners * 0.5) + (avgPay * 0.2)).clamp(1, 8);
      circles.add(
        Circle(
          circleId: CircleId('zone_${z['lat']}_${z['lng']}'),
          center: LatLng(z['lat'] as double, z['lng'] as double),
          radius: 130 + (intensity * 45),
          fillColor: AppColors.racingOrange.withOpacity(0.14),
          strokeColor: AppColors.racingOrange.withOpacity(0.45),
          strokeWidth: 2,
        ),
      );
      markers.add(
        Marker(
          markerId: MarkerId('zone_label_${z['lat']}_${z['lng']}'),
          position: LatLng(z['lat'] as double, z['lng'] as double),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: 'Zona estratégica',
            snippet:
                'Corridas: $orders | Parceiros: $partners | Ticket méd.: R\$${avgPay.toStringAsFixed(2)}',
          ),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _markers = markers;
      _marketCircles = circles;
    });
  }

  double _timeWindowWeight(int hour) {
    switch (_mapTimeWindow) {
      case MapTimeWindowOption.now:
        final now = DateTime.now().hour;
        final d = (hour - now).abs();
        if (d == 0) return 2.0;
        if (d <= 1) return 1.4;
        if (d <= 2) return 1.1;
        return 0.8;
      case MapTimeWindowOption.lunchPeak:
        return (hour >= 11 && hour <= 14) ? 1.9 : 0.9;
      case MapTimeWindowOption.eveningPeak:
        return (hour >= 18 && hour <= 22) ? 2.0 : 0.85;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
    final brightness = Theme.of(context).brightness;
    controller.setMapStyle(
      brightness == Brightness.dark ? _darkMapStyle : _lightMapStyle,
    );
  }

  // Estilo do mapa para modo claro
  static const String? _lightMapStyle =
      null; // Usa estilo padrão do Google Maps

  // Estilo do mapa para modo escuro
  static const String? _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#181818"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1b1b1b"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8a8a8a"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#373737"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#3c3c3c"
      }
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#4e4e4e"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#3d3d3d"
      }
    ]
  }
]
''';

  void _recenterMap() {
    if (_currentPosition == null) return;
    _googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _currentZoom,
      ),
    );
  }

  void _zoomIn() {
    setState(() => _currentZoom = (_currentZoom + 1).clamp(3.0, 21.0));
    if (_currentPosition != null) {
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _currentZoom,
        ),
      );
    }
  }

  void _zoomOut() {
    setState(() => _currentZoom = (_currentZoom - 1).clamp(3.0, 21.0));
    if (_currentPosition != null) {
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _currentZoom,
        ),
      );
    }
  }

  void _setMapType(MapType type) {
    setState(() => _mapType = type);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.user;
    final isRider = user?.isRider ?? true;
    final isDeliveryProfile = appState.isDeliveryPilot;
    final showDeliveryPendingBanner = isDeliveryProfile &&
        appState.deliveryModerationStatus.isAwaitingModeration;

    final initialPosition = _currentPosition ?? _defaultCenter;

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  initialPosition.latitude, initialPosition.longitude),
              zoom: _currentZoom,
            ),
            onMapCreated: _onMapCreated,
            mapType: _mapType,
            markers: _markers,
            polylines: _polylines,
            circles: _marketCircles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),
        ),

        Positioned(
          left: 16,
          top: 140,
          child: _MapControlsOverlay(
            mapType: _mapType,
            onMapTypeChanged: _setMapType,
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
          ),
        ),

        // 2. Header (topo) – transparente sobre o mapa
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ModernHeader(
            title: isRider
                ? ''
                : 'Minha Loja', // Removido "Mapa" pois está na Home
            transparentOverMap: true,
          ),
        ),

        if (showDeliveryPendingBanner)
          const Positioned(
            top: 96,
            left: 16,
            right: 16,
            child: _DeliveryPendingBanner(),
          ),

        // 3. Mensagens Rápidas – canto inferior esquerdo (acima do menu)
        Positioned(
            left: 16,
            bottom: 100,
            child: QuickMessagesCard(
              items: _quickMessages,
              maxVisible: 3,
              onSeeAll: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const _NotificationsFullSheet(),
                );
                _loadQuickMessages();
              },
            ),
          ),

        // 4. Coluna FAB – centro-direito
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: HomeMapFabColumn(
              navigationTripActive: false,
              isHeatmapOn: _heatmapOn,
              selectedFilters: _filterOptions,
              selectedTimeWindow: _mapTimeWindow,
              onDriveMode: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MaintenanceDetailScreen()),
                );
              },
              onRecenter: _recenterMap,
              onHeatmapChanged: (v) {
                setState(() => _heatmapOn = v);
                _refreshMarketIntelligenceOverlays();
              },
              onFilterChanged: (v) {
                setState(() => _filterOptions = v);
                _refreshMarketIntelligenceOverlays();
              },
              onTimeWindowChanged: (v) {
                setState(() => _mapTimeWindow = v);
                _refreshMarketIntelligenceOverlays();
              },
            ),
          ),
        ),

        // 6. Conteúdo lojista (overlay quando é partner e não rider)
        if (!isRider && _isLoading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _MapControlsOverlay extends StatelessWidget {
  final MapType mapType;
  final ValueChanged<MapType> onMapTypeChanged;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _MapControlsOverlay({
    required this.mapType,
    required this.onMapTypeChanged,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark
                  ? AppColors.panelDarkHigh.withOpacity(0.96)
                  : AppColors.panelLightHigh.withOpacity(0.96),
              isDark
                  ? AppColors.panelDarkLow.withOpacity(0.9)
                  : AppColors.panelLightLow.withOpacity(0.92),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.racingOrange.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: AppColors.raisedPanelShadows(isDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ControlButton(
              icon: LucideIcons.plus,
              onTap: onZoomIn,
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: theme.dividerColor.withOpacity(0.5),
            ),
            _ControlButton(
              icon: LucideIcons.minus,
              onTap: onZoomOut,
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: theme.dividerColor.withOpacity(0.5),
            ),
            _MapTypeChip(
              label: 'Mapa',
              type: MapType.normal,
              selected: mapType == MapType.normal,
              onTap: () => onMapTypeChanged(MapType.normal),
            ),
            _MapTypeChip(
              label: 'Satélite',
              type: MapType.satellite,
              selected: mapType == MapType.satellite,
              onTap: () => onMapTypeChanged(MapType.satellite),
            ),
            _MapTypeChip(
              label: 'Híbrido',
              type: MapType.hybrid,
              selected: mapType == MapType.hybrid,
              onTap: () => onMapTypeChanged(MapType.hybrid),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryPendingBanner extends StatelessWidget {
  const _DeliveryPendingBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.statusWarning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppColors.panelDarkHigh.withOpacity(0.95)
                : AppColors.panelLightHigh.withOpacity(0.98),
            isDark
                ? AppColors.panelDarkLow.withOpacity(0.92)
                : AppColors.panelLightLow.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: AppColors.raisedPanelShadows(isDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.info,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seu perfil de entregador esta sendo analisado. Algumas funcoes estao limitadas.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon,
              size: 16, color: theme.iconTheme.color?.withOpacity(0.85)),
        ),
      ),
    );
  }
}

class _MapTypeChip extends StatelessWidget {
  final String label;
  final MapType type;
  final bool selected;
  final VoidCallback onTap;

  const _MapTypeChip({
    required this.label,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == MapType.normal
                    ? LucideIcons.map
                    : type == MapType.satellite
                        ? LucideIcons.satellite
                        : LucideIcons.layers,
                size: 14,
                color: selected
                    ? AppColors.racingOrange.withOpacity(0.95)
                    : theme.iconTheme.color?.withOpacity(0.7),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? AppColors.racingOrange.withOpacity(0.95)
                      : theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _NotificationsFullSheet extends StatelessWidget {
  const _NotificationsFullSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Notificações',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: ApiService.getAlerts(limit: 50),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final alerts = snapshot.data!;
                    if (alerts.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma notificação',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: alerts.length,
                      itemBuilder: (context, i) {
                        final a = alerts[i];
                        final title = a['title'] as String? ?? 'Alerta';
                        final body = a['body'] as String?;
                        return ListTile(
                          title: Text(title),
                          subtitle: body != null ? Text(body) : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
