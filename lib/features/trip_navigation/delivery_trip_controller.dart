import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/delivery_order.dart';
import '../../services/api_service.dart';
import '../../services/navigation_route_cache_service.dart';
import '../../services/realtime_service.dart';
import '../../utils/delivery_geofence.dart';
import '../../utils/delivery_pickup_code.dart';
import '../../utils/delivery_proof_pin.dart';

enum DeliveryTripPhase {
  headingToStore,
  waitingAtStore,
  headingToClient,
  awaitingDeliveryProof,
}

/// Estado da corrida ativa para o experimento do Modo Corrida dedicado.
class DeliveryTripController extends ChangeNotifier {
  DeliveryTripController({required DeliveryOrder initialOrder})
      : _order = initialOrder.withoutInternalCode() {
    _phase = _phaseFromStatus(initialOrder.status);
    RealtimeService.instance.setNavigationMode(true, orderId: initialOrder.id);
  }

  DeliveryOrder _order;
  late DeliveryTripPhase _phase;
  bool _isLoading = false;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  MapBoxNavigationViewController? mapboxController;
  StreamSubscription<Position>? _positionSubscription;

  DeliveryOrder get order => _order;
  DeliveryTripPhase get phase => _phase;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  bool get navigationGuidanceActive =>
      _phase == DeliveryTripPhase.headingToStore ||
      _phase == DeliveryTripPhase.headingToClient;

  bool get canCompleteDelivery =>
      _phase == DeliveryTripPhase.awaitingDeliveryProof;

  double get destinationLatitude => _phase == DeliveryTripPhase.headingToClient
      ? _order.deliveryLatitude
      : _order.storeLatitude;

  double get destinationLongitude => _phase == DeliveryTripPhase.headingToClient
      ? _order.deliveryLongitude
      : _order.storeLongitude;

  String get destinationLabel => _phase == DeliveryTripPhase.headingToClient
      ? _order.deliveryAddress
      : _order.storeName;

  String get stageTitle {
    switch (_phase) {
      case DeliveryTripPhase.headingToStore:
        return 'Etapa 1/2: Indo para o estabelecimento';
      case DeliveryTripPhase.waitingAtStore:
        return 'Etapa 1/2: Aguardando retirada do item';
      case DeliveryTripPhase.headingToClient:
        return 'Etapa 2/2: Entrega em andamento';
      case DeliveryTripPhase.awaitingDeliveryProof:
        return 'Etapa 2/2: Confirmar entrega com o cliente';
    }
  }

  DeliveryTripPhase _phaseFromStatus(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.accepted:
        return DeliveryTripPhase.headingToStore;
      case DeliveryStatus.arrivedAtStore:
        return DeliveryTripPhase.waitingAtStore;
      case DeliveryStatus.inTransit:
      case DeliveryStatus.inProgress:
        return DeliveryTripPhase.headingToClient;
      case DeliveryStatus.arrivedAtDestination:
        return DeliveryTripPhase.awaitingDeliveryProof;
      default:
        return DeliveryTripPhase.headingToStore;
    }
  }

  Future<void> startLocationTracking() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      notifyListeners();
      _emitLocationThrottled();

      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((pos) {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _emitLocationThrottled();
      });
    } catch (e) {
      debugPrint('DeliveryTripController GPS: $e');
    }
  }

  void _emitLocationThrottled() {
    final lat = _latitude;
    final lng = _longitude;
    if (lat == null || lng == null) return;
    RealtimeService.instance.emitRiderLocationThrottled(
      lat: lat,
      lng: lng,
      orderId: _order.id,
      orderStatus: _order.status.name,
    );
  }

  Future<void> _syncLocationCheckpoint() async {
    final lat = _latitude;
    final lng = _longitude;
    if (lat == null || lng == null) return;
    try {
      await ApiService.updateUserLocation(
        latitude: lat,
        longitude: lng,
        navigationActive: true,
      );
      RealtimeService.instance.emitRiderLocationImmediate(
        lat: lat,
        lng: lng,
        orderId: _order.id,
        orderStatus: _order.status.name,
      );
    } catch (e) {
      debugPrint('DeliveryTripController checkpoint: $e');
    }
  }

  Future<void> _refreshCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      notifyListeners();
    } catch (e) {
      debugPrint('DeliveryTripController refresh GPS: $e');
    }
  }

  Future<ConfirmArrivalResult> confirmArrivalAtStore() async {
    if (_isLoading) return ConfirmArrivalResult.failed;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _refreshCurrentPosition();
      final lat = _latitude;
      final lng = _longitude;
      if (lat == null || lng == null) {
        return ConfirmArrivalResult.locationUnavailable;
      }

      if (DeliveryGeofence.requireStoreArrivalProximity) {
        final distance = DeliveryGeofence.distanceMeters(
          fromLatitude: lat,
          fromLongitude: lng,
          toLatitude: _order.storeLatitude,
          toLongitude: _order.storeLongitude,
        );
        if (distance == null ||
            distance > DeliveryGeofence.storeArrivalMaxMeters) {
          return ConfirmArrivalResult.tooFarFromStore;
        }
      }

      final updated = await ApiService.markArrivedAtStore(_order.id);
      _order = updated.withoutInternalCode();
      _phase = DeliveryTripPhase.waitingAtStore;
      _errorMessage = null;
      await _syncLocationCheckpoint();
      return ConfirmArrivalResult.confirmed;
    } catch (e) {
      _errorMessage = 'Nao foi possivel confirmar chegada: $e';
      return ConfirmArrivalResult.failed;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> collectAndStartDelivery(String pickupCode) async {
    if (_isLoading) return false;
    if (!DeliveryPickupCode.isValidFormat(pickupCode)) {
      _errorMessage = 'Informe o codigo de retirada fornecido pelo lojista.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await ApiService.startTransit(
        _order.id,
        pickupCode: DeliveryPickupCode.normalize(pickupCode),
      );
      _order = updated.withoutInternalCode();
      _phase = DeliveryTripPhase.headingToClient;
      _errorMessage = null;
      await _syncLocationCheckpoint();
      return true;
    } catch (e) {
      _errorMessage = _humanizeError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmArrivalAtDestination() async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _syncLocationCheckpoint();
      final updated = await ApiService.markArrivedAtDestination(_order.id);
      _order = updated.withoutInternalCode();
      _phase = DeliveryTripPhase.awaitingDeliveryProof;
      _errorMessage = null;
      await _endNavigationGuidance();
      return true;
    } catch (e) {
      _errorMessage = _humanizeError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeDelivery(String deliveryPin) async {
    if (_isLoading) return false;
    if (!canCompleteDelivery) {
      _errorMessage = 'Confirme a chegada ao cliente antes de finalizar.';
      notifyListeners();
      return false;
    }
    if (!DeliveryProofPin.isValidFormat(deliveryPin)) {
      _errorMessage = 'Informe os 4 digitos do PIN do cliente.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _syncLocationCheckpoint();
      await ApiService.completeOrder(
        _order.id,
        deliveryPin: deliveryPin,
      );
      await NavigationRouteCacheService.clear();
      RealtimeService.instance.setNavigationMode(false);
      RealtimeService.instance.leaveOrderTracking(_order.id);
      return true;
    } catch (e) {
      _errorMessage = _humanizeError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _endNavigationGuidance() async {
    try {
      await mapboxController?.finishNavigation();
    } catch (e) {
      debugPrint('DeliveryTripController finishNavigation: $e');
    }
  }

  String _humanizeError(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  Future<void> recenter() async {
    await mapboxController?.recenter();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
