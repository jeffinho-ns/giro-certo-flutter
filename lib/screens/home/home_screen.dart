import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/notifications_count_provider.dart';
import '../../services/api_service.dart';
import '../../services/map_service.dart';
import '../../services/realtime_service.dart';
import '../../services/navigation_route_cache_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/notification_service.dart';
import '../../models/delivery_order.dart';
import '../../models/partner.dart';
import '../../models/pilot_profile.dart';
import '../../utils/colors.dart';
import '../../utils/navigation_rider_marker.dart';
import '../../utils/delivery_status_utils.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/quick_messages_card.dart';
import '../../widgets/home_map_fab_column.dart';
import '../../widgets/delivery_pipcar_modal.dart';
import '../../widgets/home_embedded_mapbox_navigation.dart';
import '../../features/trip_navigation/trip_navigation_experiment.dart';
import '../../features/trip_navigation/trip_navigation_screen.dart';
import '../maintenance/maintenance_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MapBoxNavigationViewController? _mapboxNavController;

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
  bool _heatmapOn = false;
  Set<MapFilterOption> _filterOptions = {};
  MapTimeWindowOption _mapTimeWindow = MapTimeWindowOption.now;
  List<QuickMessageItem> _quickMessages = [];
  DeliveryOrder? _pipcarOrder;
  DeliveryOrder? _activeDeliveryOrder;
  List<DeliveryOrder> _marketPendingOrders = [];
  List<Partner> _marketPartners = [];
  bool _isUpdatingDeliveryRoute = false;

  /// Atraso após aceitar/iniciar trânsito: evita montar Mapbox no mesmo instante em que o modal
  /// fecha e o Google Map ainda compõe (reduz crash nativo, sobretudo no iOS).
  DateTime? _deferMapboxOverlayUntil;

  /// Câmera estilo navegação (tilt + bearing) no Google Map enquanto o Mapbox não assume.
  bool _googleDriveModeActive = false;

  /// Desliga o overlay Mapbox nesta sessão após falha nativa (mantém rota + drive no Google).
  bool _mapboxTripDisabled = false;

  /// Modo navegação no Google Map (ex.: aguardando retirada na loja): marcador com rotação.
  BitmapDescriptor? _riderNavIcon;
  Marker? _riderNavMarker;
  double _navBearing = 0;
  LatLng? _prevNavForBearing;
  MapType _mapType = MapType.normal;
  double _currentZoom = 15.0;

  static const LatLng _defaultCenter = LatLng(-23.5505, -46.6333);

  static const Color _googleNavBlue = Color(0xFF4285F4);

  static const double _driveZoom = 17.5;
  static const double _driveTilt = 55;

  bool get _deliveryNavigationActive => _activeDeliveryOrder != null;

  bool _isActiveTripNavigationStatus(DeliveryStatus status) {
    return status == DeliveryStatus.accepted ||
        status == DeliveryStatus.inTransit ||
        status == DeliveryStatus.inProgress;
  }

  bool _shouldApplyGoogleDriveCamera({bool? mapboxOverlayVisible}) {
    if (!_googleDriveModeActive || _currentPosition == null) return false;
    final order = _activeDeliveryOrder;
    if (order == null || !_isActiveTripNavigationStatus(order.status)) {
      return false;
    }
    if (mapboxOverlayVisible ?? _embeddedMapboxLayerActive()) return false;
    return true;
  }

  /// Mapbox em ecrã cheio na home durante etapas com navegação ativa (respeita [_deferMapboxOverlayUntil]).
  bool _embeddedMapboxLayerActive() {
    // Experimento Fase 1: overlay legado desligado; corrida na TripNavigationScreen.
    if (TripNavigationExperiment.enabled) return false;
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    final isRider = user?.isRider ?? true;
    final o = _activeDeliveryOrder;
    if (!isRider || o == null || _currentPosition == null) return false;
    if (_mapboxTripDisabled) return false;
    final defer = _deferMapboxOverlayUntil;
    if (defer != null && DateTime.now().isBefore(defer)) return false;
    final s = o.status;
    return s == DeliveryStatus.accepted ||
        s == DeliveryStatus.inTransit ||
        s == DeliveryStatus.inProgress;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final q =
        sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    return 2 * earth * math.asin(math.min(1.0, math.sqrt(q)));
  }

  double _bearingBetween(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final brng = math.atan2(y, x) * 180 / math.pi;
    return (brng + 360) % 360;
  }

  void _updateNavBearingFromPosition(Position pos) {
    final cur = LatLng(pos.latitude, pos.longitude);
    final h = pos.heading;
    if (h >= 0 && h <= 360) {
      _navBearing = h;
      _prevNavForBearing = cur;
      return;
    }
    if (_prevNavForBearing != null) {
      final d = _distanceMeters(_prevNavForBearing!, cur);
      if (d >= 4) {
        _navBearing = _bearingBetween(_prevNavForBearing!, cur);
        _prevNavForBearing = cur;
      }
    } else {
      _prevNavForBearing = cur;
    }
  }

  void _rebuildRiderNavMarker() {
    if (!_deliveryNavigationActive || _currentPosition == null) {
      _riderNavMarker = null;
      return;
    }
    _riderNavMarker = Marker(
      markerId: const MarkerId('rider_nav'),
      position: _currentPosition!,
      rotation: _navBearing,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      icon: _riderNavIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      zIndexInt: 999,
    );
  }

  void _applyGoogleDriveCamera({bool animated = true}) {
    if (!_shouldApplyGoogleDriveCamera()) return;
    final pos = _currentPosition;
    final controller = _googleMapController;
    if (pos == null || controller == null) return;
    final update = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: pos,
        zoom: _driveZoom,
        bearing: _navBearing,
        tilt: _driveTilt,
      ),
    );
    if (animated) {
      controller.animateCamera(update);
    } else {
      controller.moveCamera(update);
    }
  }

  Future<void> _resetGoogleMapToOverview({double? zoom}) async {
    final pos = _currentPosition;
    final controller = _googleMapController;
    if (pos == null || controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: zoom ?? _currentZoom,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );
  }

  Future<void> _previewRouteBoundsThenDrive(
    List<Map<String, double>> points,
  ) async {
    if (!_shouldApplyGoogleDriveCamera()) return;
    if (points.length >= 2) {
      final bounds = _toLlBounds(points);
      await _googleMapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 72),
      );
      if (!mounted || !_shouldApplyGoogleDriveCamera()) return;
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    if (!mounted || !_shouldApplyGoogleDriveCamera()) return;
    _applyGoogleDriveCamera();
  }

  void _onMapboxNavigationFailed() {
    if (!mounted) return;
    setState(() => _mapboxTripDisabled = true);
    _applyGoogleDriveCamera();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Navegacao Mapbox indisponivel. Continuando com rota e modo conducao no mapa.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _snapNavigationCameraNow() {
    if (_shouldApplyGoogleDriveCamera()) {
      _applyGoogleDriveCamera();
      return;
    }
    if (!_deliveryNavigationActive || _currentPosition == null) return;
    _googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _currentZoom,
      ),
    );
  }

  Set<Marker> get _allMapMarkers => {
        ..._markers,
        if (_riderNavMarker != null) _riderNavMarker!,
      };

  @override
  void initState() {
    super.initState();
    NavigationRiderMarker.bitmap().then((icon) {
      if (!mounted) return;
      setState(() {
        _riderNavIcon = icon;
        _rebuildRiderNavMarker();
      });
    });
    _loadQuickMessages();
    _requestLocationAndListen();
    _loadPartnerData();
    _loadMarketIntelligenceData();
    _subscribePartnerRealtimeUpdates();
    _syncDeliveryModerationStatus();
    _pollPendingDeliveriesForRider();
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
      _updateNavBearingFromPosition(pos);
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _rebuildRiderNavMarker();
      });
      _updateUserLocation(
        pos.latitude,
        pos.longitude,
        activeOrder: _activeDeliveryOrder,
      );
      if (_deliveryNavigationActive) _snapNavigationCameraNow();

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((Position pos) {
        if (!mounted) return;
        _updateNavBearingFromPosition(pos);
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          _rebuildRiderNavMarker();
        });
        _updateUserLocation(
          pos.latitude,
          pos.longitude,
          activeOrder: _activeDeliveryOrder,
        );
        if (_shouldApplyGoogleDriveCamera()) {
          _applyGoogleDriveCamera(animated: false);
        } else if (_deliveryNavigationActive) {
          _snapNavigationCameraNow();
        }
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
  }

  /// HTTP `PUT /users/me/location` apenas em marcos da corrida (persistência explícita).
  Future<void> _syncUserLocationPutForCheckpoint() async {
    final p = _currentPosition;
    if (p == null) return;
    final active = _activeDeliveryOrder;
    try {
      await ApiService.updateUserLocation(
        latitude: p.latitude,
        longitude: p.longitude,
        navigationActive: active != null,
      );
      RealtimeService.instance.emitRiderLocationImmediate(
        lat: p.latitude,
        lng: p.longitude,
        orderId: active?.id,
        orderStatus: active?.status.name,
      );
    } catch (e) {
      debugPrint('Falha ao sincronizar localizacao (checkpoint): $e');
    }
  }

  Future<void> _pollPendingDeliveriesForRider() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.user?.isRider != true) return;
    while (mounted) {
      try {
        await _syncDeliveryModerationStatus();
        final isDeliveryProfile = appState.isDeliveryPilot;
        final isDeliveryApproved = appState.deliveryModerationStatus ==
            DeliveryModerationStatus.approved;

        if (isDeliveryProfile && !isDeliveryApproved) {
          if (_pipcarOrder != null && mounted) {
            setState(() => _pipcarOrder = null);
          }
          await Future.delayed(const Duration(seconds: 15));
          continue;
        }

        if (_activeDeliveryOrder != null ||
            TripNavigationExperiment.activeSessionOpen) {
          await Future.delayed(const Duration(seconds: 15));
          continue;
        }

        final orders =
            await ApiService.getDeliveryOrders(status: 'pending', limit: 10);
        if (!mounted) break;
        if (orders.isNotEmpty && _pipcarOrder == null) {
          setState(() => _pipcarOrder = orders.first);
        }
      } catch (e) {
        debugPrint('Falha ao consultar corridas pendentes: $e');
      }
      await Future.delayed(const Duration(seconds: 15));
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
    if (_deliveryNavigationActive) return;
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
      _rebuildRiderNavMarker();
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
    if (_embeddedMapboxLayerActive()) {
      unawaited(_mapboxNavController?.recenter());
      return;
    }
    if (_shouldApplyGoogleDriveCamera()) {
      _applyGoogleDriveCamera();
      return;
    }
    if (_deliveryNavigationActive) {
      _snapNavigationCameraNow();
      return;
    }
    _googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _currentZoom,
      ),
    );
  }

  void _zoomIn() {
    if (_embeddedMapboxLayerActive()) return;
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
    if (_embeddedMapboxLayerActive()) return;
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

  Polyline _navStylePolyline({
    required PolylineId polylineId,
    required List<LatLng> points,
  }) {
    return Polyline(
      polylineId: polylineId,
      points: points,
      color: _googleNavBlue,
      width: 14,
      geodesic: true,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  LatLngBounds _toLlBounds(List<Map<String, double>> points) {
    final lats = points.map((e) => e['lat']!).toList();
    final lngs = points.map((e) => e['lng']!).toList();
    return LatLngBounds(
      southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );
  }

  /// Preview no Google Map (sempre visível durante [ _deferMapboxOverlayUntil ] e fallback).
  Future<void> _drawRouteToStore(DeliveryOrder order) async {
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    final originLat = user?.currentLat ??
        _currentPosition?.latitude ??
        _defaultCenter.latitude;
    final originLng = user?.currentLng ??
        _currentPosition?.longitude ??
        _defaultCenter.longitude;

    final routeResult = await MapService.getRoutePoints(
      originLat: originLat,
      originLng: originLng,
      destLat: order.storeLatitude,
      destLng: order.storeLongitude,
    );
    final points = routeResult.points;
    if (points.isEmpty) return;

    if (!mounted) return;
    if (!routeResult.followsRoads) {
      final detail = routeResult.errorMessage ?? routeResult.directionsStatus;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            detail != null && detail.isNotEmpty
                ? 'Preview: rota aproximada ($detail).'
                : 'Preview: rota aproximada. Navegacao Mapbox segue por vias.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
    final latLngPoints =
        points.map((p) => LatLng(p['lat']!, p['lng']!)).toList();
    await NavigationRouteCacheService.saveRoute(
        orderId: order.id, points: points);
    setState(() {
      _polylines = {
        _navStylePolyline(
          polylineId: const PolylineId('route_to_store'),
          points: latLngPoints,
        ),
      };
      _markers = {
        Marker(
          markerId: const MarkerId('store'),
          position: LatLng(order.storeLatitude, order.storeLongitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      };
      _marketCircles = {};
      _rebuildRiderNavMarker();
    });

    if (_googleDriveModeActive) {
      await _previewRouteBoundsThenDrive(points);
    } else if (_deliveryNavigationActive && _currentPosition != null) {
      _snapNavigationCameraNow();
    } else {
      final bounds = _toLlBounds(points);
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    }
  }

  Future<void> _drawRouteStoreToClient(DeliveryOrder order) async {
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    final originLat =
        user?.currentLat ?? _currentPosition?.latitude ?? order.storeLatitude;
    final originLng =
        user?.currentLng ?? _currentPosition?.longitude ?? order.storeLongitude;

    final routeResult = await MapService.getRoutePoints(
      originLat: originLat,
      originLng: originLng,
      destLat: order.deliveryLatitude,
      destLng: order.deliveryLongitude,
    );
    final points = routeResult.points;
    if (points.isEmpty) return;

    if (!mounted) return;
    if (!routeResult.followsRoads) {
      final detail = routeResult.errorMessage ?? routeResult.directionsStatus;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            detail != null && detail.isNotEmpty
                ? 'Preview: rota aproximada ($detail).'
                : 'Preview: rota aproximada. Navegacao Mapbox segue por vias.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
    final latLngPoints =
        points.map((p) => LatLng(p['lat']!, p['lng']!)).toList();
    await NavigationRouteCacheService.saveRoute(
        orderId: order.id, points: points);
    setState(() {
      _polylines = {
        _navStylePolyline(
          polylineId: const PolylineId('route_to_client'),
          points: latLngPoints,
        ),
      };
      _markers = {
        Marker(
          markerId: const MarkerId('store'),
          position: LatLng(order.storeLatitude, order.storeLongitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(order.deliveryLatitude, order.deliveryLongitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };
      _marketCircles = {};
      _rebuildRiderNavMarker();
    });

    if (_googleDriveModeActive) {
      await _previewRouteBoundsThenDrive(points);
    } else if (_deliveryNavigationActive && _currentPosition != null) {
      _snapNavigationCameraNow();
    } else {
      final bounds = _toLlBounds(points);
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    }
  }

  void _acceptPipcar(DeliveryOrder order) async {
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _pipcarOrder = null);
    try {
      final accepted = await ApiService.acceptOrder(
        order.id,
        riderId: user.id,
        riderName: user.name,
      );
      if (!mounted) return;

      if (TripNavigationExperiment.enabled) {
        RealtimeService.instance.setNavigationMode(true, orderId: accepted.id);
        await _syncUserLocationPutForCheckpoint();
        if (!mounted) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => TripNavigationScreen(initialOrder: accepted),
          ),
        );
        return;
      }

      setState(() {
        _activeDeliveryOrder = accepted;
        _googleDriveModeActive = true;
        _mapboxTripDisabled = false;
        _deferMapboxOverlayUntil =
            DateTime.now().add(const Duration(milliseconds: 200));
      });
      RealtimeService.instance.setNavigationMode(true, orderId: accepted.id);
      await _drawRouteToStore(accepted);
      if (!mounted) return;
      await _syncUserLocationPutForCheckpoint();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aceitar: $e')),
        );
      }
    }
  }

  Future<void> _confirmArrivalAtStore() async {
    final order = _activeDeliveryOrder;
    if (order == null) return;

    setState(() => _isUpdatingDeliveryRoute = true);
    try {
      final arrivedOrder = await ApiService.markArrivedAtStore(order.id);
      if (!mounted) return;
      setState(() {
        _activeDeliveryOrder = arrivedOrder;
        _googleDriveModeActive = false;
        _deferMapboxOverlayUntil = null;
      });
      await _resetGoogleMapToOverview(zoom: 16);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Chegada confirmada. Aguardando retirada do pedido.')),
      );
      await _syncUserLocationPutForCheckpoint();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel confirmar chegada: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingDeliveryRoute = false);
      }
    }
  }

  Future<void> _collectAndStartDelivery() async {
    final order = _activeDeliveryOrder;
    if (order == null) return;
    final pickupCode = await _promptPickupCode(order);
    if (pickupCode == null || pickupCode.isEmpty) return;

    setState(() => _isUpdatingDeliveryRoute = true);
    try {
      final inTransitOrder =
          await ApiService.startTransit(order.id, pickupCode: pickupCode);
      if (!mounted) return;
      setState(() {
        _activeDeliveryOrder = inTransitOrder;
        _googleDriveModeActive = true;
        _mapboxTripDisabled = false;
        _deferMapboxOverlayUntil =
            DateTime.now().add(const Duration(milliseconds: 200));
      });
      await _drawRouteStoreToClient(inTransitOrder);
      if (!mounted) return;
      await _syncUserLocationPutForCheckpoint();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega iniciada. Siga para o cliente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Nao foi possivel atualizar a etapa da corrida: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingDeliveryRoute = false);
      }
    }
  }

  Future<String?> _promptPickupCode(DeliveryOrder order) async {
    final controller = TextEditingController();
    final expected = (order.internalCode ?? '').trim();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar retirada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expected.isNotEmpty)
                Text(
                  'Código da loja: $expected',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 8),
              const Text('Digite o código interno para iniciar a entrega.'),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'GC-XXXXXXXX',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pop(controller.text.trim().toUpperCase()),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeDelivery() async {
    final order = _activeDeliveryOrder;
    if (order == null) return;

    setState(() => _isUpdatingDeliveryRoute = true);
    try {
      await _syncUserLocationPutForCheckpoint();
      await ApiService.completeOrder(order.id);
      if (!mounted) return;
      setState(() {
        _activeDeliveryOrder = null;
        _googleDriveModeActive = false;
        _mapboxTripDisabled = false;
        _mapboxNavController = null;
        _deferMapboxOverlayUntil = null;
        _polylines = {};
        _markers = {};
        _marketCircles = {};
        _riderNavMarker = null;
        _prevNavForBearing = null;
      });
      _refreshMarketIntelligenceOverlays();
      RealtimeService.instance.setNavigationMode(false);
      RealtimeService.instance.leaveOrderTracking(order.id);
      await NavigationRouteCacheService.clear();
      await _resetGoogleMapToOverview();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega finalizada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel finalizar a entrega: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingDeliveryRoute = false);
      }
    }
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
    final useEmbeddedMapbox = _embeddedMapboxLayerActive();
    final showMapboxOverlay = useEmbeddedMapbox &&
        _activeDeliveryOrder != null &&
        _currentPosition != null;
    final googleDriveCamera = _shouldApplyGoogleDriveCamera(
      mapboxOverlayVisible: showMapboxOverlay,
    );

    final tripNavActive = _activeDeliveryOrder != null &&
        _isActiveTripNavigationStatus(_activeDeliveryOrder!.status);

    return Stack(
      children: [
        // 1. Google Map mantém-se montado; Mapbox é uma camada por cima (evita crash ao trocar
        // duas platform views no mesmo frame).
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                ignoring: showMapboxOverlay,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                        initialPosition.latitude, initialPosition.longitude),
                    zoom: _currentZoom,
                  ),
                  onMapCreated: _onMapCreated,
                  mapType: _mapType,
                  markers: _allMapMarkers,
                  polylines: _polylines,
                  circles: _marketCircles,
                  myLocationEnabled: !googleDriveCamera,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                ),
              ),
              if (showMapboxOverlay)
                Positioned.fill(
                  child: HomeEmbeddedMapboxNavigation(
                    key: ValueKey(
                      '${_activeDeliveryOrder!.id}_${_activeDeliveryOrder!.status.name}',
                    ),
                    order: _activeDeliveryOrder!,
                    originLatitude: _currentPosition!.latitude,
                    originLongitude: _currentPosition!.longitude,
                    onControllerReady: (c) => _mapboxNavController = c,
                    onNavigationFailed: _onMapboxNavigationFailed,
                  ),
                ),
            ],
          ),
        ),

        // 1b. Controles do mapa (só com Google Map)
        if (!useEmbeddedMapbox)
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
        if (!tripNavActive)
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
              navigationTripActive: useEmbeddedMapbox,
              isHeatmapOn: _heatmapOn,
              selectedFilters: _filterOptions,
              selectedTimeWindow: _mapTimeWindow,
              onDriveMode: useEmbeddedMapbox
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MaintenanceDetailScreen()),
                      );
                    },
              onRecenter: _recenterMap,
              onHeatmapChanged: useEmbeddedMapbox
                  ? null
                  : (v) {
                      setState(() => _heatmapOn = v);
                      _refreshMarketIntelligenceOverlays();
                    },
              onFilterChanged: useEmbeddedMapbox
                  ? null
                  : (v) {
                      setState(() => _filterOptions = v);
                      _refreshMarketIntelligenceOverlays();
                    },
              onTimeWindowChanged: useEmbeddedMapbox
                  ? null
                  : (v) {
                      setState(() => _mapTimeWindow = v);
                      _refreshMarketIntelligenceOverlays();
                    },
            ),
          ),
        ),

        // 5. Modal pipcar (corrida disponível) – centro
        if (_pipcarOrder != null)
          Positioned.fill(
            child: Container(
              color: Colors.black38,
              child: DeliveryPipcarModal(
                order: _pipcarOrder!,
                onAccept: () => _acceptPipcar(_pipcarOrder!),
                onReject: () => setState(() => _pipcarOrder = null),
              ),
            ),
          ),

        // 6. Conteúdo lojista (overlay quando é partner e não rider)
        if (!isRider && _isLoading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),

        if (_activeDeliveryOrder != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 105,
            child: _DeliveryTripStageCard(
              order: _activeDeliveryOrder!,
              isLoading: _isUpdatingDeliveryRoute,
              onArrivedAtStore: _confirmArrivalAtStore,
              onCollectAndStart: _collectAndStartDelivery,
              onCompleteDelivery: _completeDelivery,
            ),
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

class _DeliveryTripStageCard extends StatelessWidget {
  final DeliveryOrder order;
  final bool isLoading;
  final VoidCallback onArrivedAtStore;
  final VoidCallback onCollectAndStart;
  final VoidCallback onCompleteDelivery;

  const _DeliveryTripStageCard({
    required this.order,
    required this.isLoading,
    required this.onArrivedAtStore,
    required this.onCollectAndStart,
    required this.onCompleteDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHeadingToStore = order.status == DeliveryStatus.accepted;
    final isWaitingPickup = order.status == DeliveryStatus.arrivedAtStore;
    final isInTransit = order.status == DeliveryStatus.inTransit ||
        order.status == DeliveryStatus.inProgress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppColors.panelDarkHigh.withOpacity(0.96)
                : AppColors.panelLightHigh.withOpacity(0.98),
            isDark
                ? AppColors.panelDarkLow.withOpacity(0.93)
                : AppColors.panelLightLow.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.racingOrange.withOpacity(0.28)),
        boxShadow: AppColors.raisedPanelShadows(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isHeadingToStore
                ? 'Etapa 1/2: Indo para o estabelecimento'
                : isWaitingPickup
                    ? 'Etapa 1/2: Aguardando retirada do item'
                    : 'Etapa 2/2: Entrega em andamento',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isHeadingToStore || isWaitingPickup
                ? order.storeAddress
                : order.deliveryAddress,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isHeadingToStore) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onArrivedAtStore,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.flag, size: 18),
                label: Text(isLoading
                    ? 'Atualizando rota...'
                    : 'Cheguei no estabelecimento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.racingOrangeDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                  ),
                ),
              ),
            ),
          ],
          if (isWaitingPickup) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onCollectAndStart,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.package, size: 18),
                label: Text(
                    isLoading ? 'Atualizando...' : 'Coletar e iniciar entrega'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                  ),
                ),
              ),
            ),
          ],
          if (isInTransit) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'A rota e a navegacao Mapbox aparecem no mapa. Finalize quando entregar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onCompleteDelivery,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.checkCircle, size: 18),
                label: Text(isLoading ? 'Finalizando...' : 'Finalizar entrega'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
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
    );
  }
}
