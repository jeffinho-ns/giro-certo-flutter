import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/notifications_count_provider.dart';
import '../../services/api_service.dart';
import '../../services/map_service.dart';
import '../../models/delivery_order.dart';
import '../../models/user.dart';
import '../../models/pilot_profile.dart';
import '../../utils/colors.dart';
import '../../utils/navigation_rider_marker.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/quick_messages_card.dart';
import '../../widgets/home_map_fab_column.dart';
import '../../widgets/delivery_pipcar_modal.dart';
import '../maintenance/maintenance_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _isLoading = false;
  StreamSubscription<Position>? _positionSubscription;
  bool _heatmapOn = false;
  Set<MapFilterOption> _filterOptions = {};
  List<QuickMessageItem> _quickMessages = [];
  DeliveryOrder? _pipcarOrder;
  DeliveryOrder? _activeDeliveryOrder;
  bool _isUpdatingDeliveryRoute = false;
  /// Modo “navegação” (corrida ativa): polyline azul, câmera 3D e marcador com rotação.
  BitmapDescriptor? _riderNavIcon;
  Marker? _riderNavMarker;
  double _navBearing = 0;
  LatLng? _prevNavForBearing;
  int _lastNavCameraMs = 0;
  MapType _mapType = MapType.normal;
  double _currentZoom = 15.0;
  static const Duration _cameraAnimationDuration = Duration(milliseconds: 800);

  static const LatLng _defaultCenter = LatLng(-23.5505, -46.6333);

  static const Color _googleNavBlue = Color(0xFF4285F4);

  bool get _deliveryNavigationActive => _activeDeliveryOrder != null;

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

  double _distanceMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final q = sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    return 2 * earth * math.asin(math.min(1.0, math.sqrt(q)));
  }

  double _bearingBetween(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
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

  void _followNavigationCameraThrottled() {
    if (!_deliveryNavigationActive ||
        _mapController == null ||
        _currentPosition == null) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNavCameraMs < 650) return;
    _lastNavCameraMs = now;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 17,
          tilt: 52,
          bearing: _navBearing,
        ),
      ),
      duration: const Duration(milliseconds: 600),
    );
  }

  void _snapNavigationCameraNow() {
    _lastNavCameraMs = 0;
    _followNavigationCameraThrottled();
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
    _syncDeliveryModerationStatus();
    _pollPendingDeliveriesForRider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final p = Provider.of<NotificationsCountProvider>(context, listen: false);
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
    if (_mapController == null) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mapStyle = isDark ? _darkMapStyle : _lightMapStyle;
    if (mapStyle != null) {
      await _mapController!.setMapStyle(mapStyle);
    } else {
      await _mapController!.setMapStyle(null);
    }
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
          return QuickMessageItem(icon: icon, color: color, title: title, subtitle: body);
        }).toList();
      });
    } catch (e) {
      debugPrint('Falha ao carregar mensagens rapidas: $e');
      setState(() {
        _quickMessages = [
          const QuickMessageItem(icon: LucideIcons.checkCircle, color: AppColors.statusOk, title: 'Sistema ativo', subtitle: 'Sem alertas recentes'),
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
      _updateUserLocation(pos.latitude, pos.longitude);
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
        _updateUserLocation(pos.latitude, pos.longitude);
        if (_deliveryNavigationActive) {
          _followNavigationCameraThrottled();
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

  Future<void> _updateUserLocation(double lat, double lng) async {
    try {
      await ApiService.updateUserLocation(latitude: lat, longitude: lng);
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final user = appState.user;
      if (user != null) {
        appState.setUser(user.copyWith(currentLat: lat, currentLng: lng));
      }
    } catch (e) {
      debugPrint('Falha ao atualizar localizacao no servidor: $e');
    }
  }

  Future<void> _pollPendingDeliveriesForRider() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.user?.isRider != true) return;
    while (mounted) {
      try {
        await _syncDeliveryModerationStatus();
        final isDeliveryProfile = appState.user?.userType == UserType.delivery;
        final isDeliveryApproved =
            appState.deliveryModerationStatus == DeliveryModerationStatus.approved;

        if (isDeliveryProfile && !isDeliveryApproved) {
          if (_pipcarOrder != null && mounted) {
            setState(() => _pipcarOrder = null);
          }
          await Future.delayed(const Duration(seconds: 15));
          continue;
        }

        if (_activeDeliveryOrder != null) {
          await Future.delayed(const Duration(seconds: 15));
          continue;
        }

        final orders = await ApiService.getDeliveryOrders(status: 'pending', limit: 10);
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
    final user = appState.user;
    if (user?.userType != UserType.delivery) return;

    try {
      final reg = await ApiService.getDeliveryRegistrationStatus();
      if (!mounted) return;
      final rawStatus = (reg?['status'] as String?)?.toUpperCase();
      final nextStatus = rawStatus == 'APPROVED'
          ? DeliveryModerationStatus.approved
          : DeliveryModerationStatus.pending;

      if (appState.deliveryModerationStatus != nextStatus) {
        appState.setDeliveryModerationStatus(nextStatus);
      }
    } catch (e) {
      debugPrint('Falha ao sincronizar aprovacao de delivery: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerData() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null || !user.isPartner) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.getDeliveryOrders(storeId: user.partnerId);
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Falha ao carregar dados do parceiro: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, _currentZoom),
        duration: _cameraAnimationDuration,
      );
    }
    
    // Aplicar estilo do mapa baseado no tema atual
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mapStyle = isDark ? _darkMapStyle : _lightMapStyle;
    if (mapStyle != null) {
      await controller.setMapStyle(mapStyle);
    }
  }
  
  // Estilo do mapa para modo claro
  static const String? _lightMapStyle = null; // Usa estilo padrão do Google Maps
  
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
    if (_mapController == null || _currentPosition == null) return;
    if (_deliveryNavigationActive) {
      _snapNavigationCameraNow();
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition!, _currentZoom),
      duration: _cameraAnimationDuration,
    );
  }

  void _zoomIn() {
    if (_mapController == null) return;
    setState(() => _currentZoom = (_currentZoom + 1).clamp(3.0, 21.0));
    _mapController!.animateCamera(
      CameraUpdate.zoomIn(),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _zoomOut() {
    if (_mapController == null) return;
    setState(() => _currentZoom = (_currentZoom - 1).clamp(3.0, 21.0));
    _mapController!.animateCamera(
      CameraUpdate.zoomOut(),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _setMapType(MapType type) {
    setState(() => _mapType = type);
  }

  Future<void> _drawRouteToStore(DeliveryOrder order) async {
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    final originLat = user?.currentLat ?? _currentPosition?.latitude ?? _defaultCenter.latitude;
    final originLng = user?.currentLng ?? _currentPosition?.longitude ?? _defaultCenter.longitude;

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
                ? 'Rota em linha reta (Directions: $detail). Ajuste a chave/restricoes no Google Cloud.'
                : 'Rota em linha reta: verifique a chave GOOGLE_DIRECTIONS_API_KEY no Google Cloud.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    setState(() {
      _polylines = {
        _navStylePolyline(
          polylineId: const PolylineId('route_to_store'),
          points: points.map((p) => LatLng(p['lat']!, p['lng']!)).toList(),
        ),
      };
      _markers = {
        Marker(
          markerId: const MarkerId('store'),
          position: LatLng(order.storeLatitude, order.storeLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      };
      _rebuildRiderNavMarker();
    });

    if (_deliveryNavigationActive &&
        _mapController != null &&
        _currentPosition != null) {
      _snapNavigationCameraNow();
    } else {
      final bounds = _computeBounds(points);
      if (bounds != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 60),
          duration: _cameraAnimationDuration,
        );
      }
    }
  }

  Future<void> _drawRouteStoreToClient(DeliveryOrder order) async {
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    final originLat = user?.currentLat ?? _currentPosition?.latitude ?? order.storeLatitude;
    final originLng = user?.currentLng ?? _currentPosition?.longitude ?? order.storeLongitude;

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
                ? 'Rota em linha reta (Directions: $detail). Ajuste a chave/restricoes no Google Cloud.'
                : 'Rota em linha reta: verifique a chave GOOGLE_DIRECTIONS_API_KEY no Google Cloud.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    setState(() {
      _polylines = {
        _navStylePolyline(
          polylineId: const PolylineId('route_to_client'),
          points: points.map((p) => LatLng(p['lat']!, p['lng']!)).toList(),
        ),
      };
      _markers = {
        Marker(
          markerId: const MarkerId('store'),
          position: LatLng(order.storeLatitude, order.storeLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(order.deliveryLatitude, order.deliveryLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };
      _rebuildRiderNavMarker();
    });

    if (_deliveryNavigationActive &&
        _mapController != null &&
        _currentPosition != null) {
      _snapNavigationCameraNow();
    } else {
      final bounds = _computeBounds(points);
      if (bounds != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 60),
          duration: _cameraAnimationDuration,
        );
      }
    }
  }

  LatLngBounds? _computeBounds(List<Map<String, double>> points) {
    if (points.isEmpty) return null;
    double minLat = points.first['lat']!, maxLat = minLat;
    double minLng = points.first['lng']!, maxLng = minLng;
    for (final p in points) {
      final lat = p['lat']!;
      final lng = p['lng']!;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
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
      setState(() {
        _activeDeliveryOrder = accepted;
      });
      await _drawRouteToStore(accepted);
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
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chegada confirmada. Aguardando retirada do pedido.')),
      );
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

    setState(() => _isUpdatingDeliveryRoute = true);
    try {
      final inTransitOrder = await ApiService.startTransit(order.id);
      if (!mounted) return;
      setState(() {
        _activeDeliveryOrder = inTransitOrder;
      });
      await _drawRouteStoreToClient(inTransitOrder);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega iniciada. Siga para o cliente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel atualizar a etapa da corrida: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingDeliveryRoute = false);
      }
    }
  }

  Future<void> _completeDelivery() async {
    final order = _activeDeliveryOrder;
    if (order == null) return;

    setState(() => _isUpdatingDeliveryRoute = true);
    try {
      await ApiService.completeOrder(order.id);
      if (!mounted) return;
      setState(() {
        _activeDeliveryOrder = null;
        _polylines = {};
        _markers = {};
        _riderNavMarker = null;
        _prevNavForBearing = null;
      });
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
    final isDeliveryProfile = user?.userType == UserType.delivery;
    final showDeliveryPendingBanner =
        appState.deliveryModerationStatus == DeliveryModerationStatus.pending &&
            isDeliveryProfile;

    final initialPosition = _currentPosition ?? _defaultCenter;

    return Stack(
      children: [
        // 1. Fundo: GoogleMap (dinâmico e animado)
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: _currentZoom,
              tilt: 0,
              bearing: 0,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: !_deliveryNavigationActive,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            polylines: _polylines,
            markers: _allMapMarkers,
            mapType: _mapType,
            minMaxZoomPreference: const MinMaxZoomPreference(4, 19),
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),
        ),

        // 1b. Controles do mapa: zoom +/-, tipo de mapa (Normal / Satélite / Híbrido)
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
            title: isRider ? '' : 'Minha Loja', // Removido "Mapa" pois está na Home
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
              isHeatmapOn: _heatmapOn,
              selectedFilters: _filterOptions,
              onDriveMode: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MaintenanceDetailScreen()),
                );
              },
              onRecenter: _recenterMap,
              onHeatmapChanged: (v) => setState(() => _heatmapOn = v),
              onFilterChanged: (v) => setState(() => _filterOptions = v),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.black.withOpacity(0.35)
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
    final accent = AppColors.statusWarning;
    final bgColor = theme.brightness == Brightness.dark
        ? AppColors.darkSurface.withOpacity(0.92)
        : AppColors.lightSurface.withOpacity(0.95);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
          child: Icon(icon, size: 16, color: theme.iconTheme.color?.withOpacity(0.85)),
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
                color: selected ? AppColors.racingOrange.withOpacity(0.95) : theme.iconTheme.color?.withOpacity(0.7),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.racingOrange.withOpacity(0.95) : theme.textTheme.bodySmall?.color?.withOpacity(0.75),
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
    final isHeadingToStore = order.status == DeliveryStatus.accepted;
    final isWaitingPickup = order.status == DeliveryStatus.arrivedAtStore;
    final isInTransit = order.status == DeliveryStatus.inTransit ||
        order.status == DeliveryStatus.inProgress;
    final cardColor = theme.brightness == Brightness.dark
        ? AppColors.darkSurface.withOpacity(0.95)
        : AppColors.lightSurface.withOpacity(0.96);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.racingOrange.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                label: Text(isLoading ? 'Atualizando rota...' : 'Cheguei no estabelecimento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.racingOrange,
                  foregroundColor: Colors.white,
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
                label: Text(isLoading ? 'Atualizando...' : 'Coletar e iniciar entrega'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusOk,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
          if (isInTransit) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Siga a rota ate o cliente e finalize quando entregar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
                  backgroundColor: AppColors.statusOk,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
