import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/trip_navigation/trip_navigation_experiment.dart';
import '../models/delivery_offer_payload.dart';
import '../models/delivery_order.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../utils/delivery_status_utils.dart';

/// Ofertas em tempo real e corrida ativa do entregador (global no app).
class RiderDeliverySessionProvider extends ChangeNotifier {
  DeliveryOfferPayload? _pendingOffer;
  DeliveryOrder? _activeTripOrder;
  StreamSubscription<DeliveryOfferPayload>? _offerSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliveryStatusSubscription;
  String? _attachedRiderId;
  bool _isDeliveryPilot = false;
  bool _isDeliveryApproved = true;

  DeliveryOfferPayload? get pendingOffer => _pendingOffer;
  DeliveryOrder? get activeTripOrder => _activeTripOrder;

  bool get hasActiveTrip => _activeTripOrder != null;

  bool get shouldShowResumeTrip =>
      _activeTripOrder != null && !TripNavigationExperiment.activeSessionOpen;

  void attach({
    required String riderId,
    required bool isDeliveryPilot,
    required bool isDeliveryApproved,
  }) {
    if (_attachedRiderId == riderId &&
        _isDeliveryPilot == isDeliveryPilot &&
        _isDeliveryApproved == isDeliveryApproved &&
        _offerSubscription != null) {
      return;
    }

    detach();
    _attachedRiderId = riderId;
    _isDeliveryPilot = isDeliveryPilot;
    _isDeliveryApproved = isDeliveryApproved;

    _offerSubscription =
        RealtimeService.instance.onDeliveryNewOrderOffer.listen(_onOffer);
    _notificationSubscription =
        RealtimeService.instance.onNotification.listen(_onNotification);
    _deliveryStatusSubscription =
        RealtimeService.instance.onDeliveryStatusChanged.listen(_onDeliveryStatus);

    unawaited(refreshActiveTrip(riderId));
  }

  void detach() {
    _offerSubscription?.cancel();
    _notificationSubscription?.cancel();
    _deliveryStatusSubscription?.cancel();
    _offerSubscription = null;
    _notificationSubscription = null;
    _deliveryStatusSubscription = null;
    _attachedRiderId = null;
    _pendingOffer = null;
    _activeTripOrder = null;
    notifyListeners();
  }

  void presentOffer(DeliveryOfferPayload offer) {
    if (!_canReceiveOffers) return;
    if (TripNavigationExperiment.activeSessionOpen) return;
    if (_activeTripOrder != null) return;
    _pendingOffer = offer;
    notifyListeners();
  }

  void dismissOffer() {
    if (_pendingOffer == null) return;
    _pendingOffer = null;
    notifyListeners();
  }

  void setActiveTrip(DeliveryOrder order) {
    _pendingOffer = null;
    _activeTripOrder = order.withoutInternalCode();
    notifyListeners();
  }

  void updateActiveTrip(DeliveryOrder order) {
    if (_activeTripOrder?.id != order.id) return;
    _activeTripOrder = order.withoutInternalCode();
    notifyListeners();
  }

  void clearActiveTrip() {
    if (_activeTripOrder == null) return;
    _activeTripOrder = null;
    notifyListeners();
  }

  Future<void> refreshActiveTrip(String riderId) async {
    try {
      final orders = await ApiService.getDeliveryOrders(
        riderId: riderId,
        hidePickupCode: true,
      );
      DeliveryOrder? active;
      for (final order in orders) {
        if (DeliveryStatusUtils.isActive(order.status)) {
          active = order;
          break;
        }
      }
      _activeTripOrder = active;
      notifyListeners();
    } catch (e) {
      debugPrint('Falha ao sincronizar corrida ativa: $e');
    }
  }

  bool get _canReceiveOffers {
    if (_attachedRiderId == null) return false;
    if (_isDeliveryPilot && !_isDeliveryApproved) return false;
    return true;
  }

  void _onOffer(DeliveryOfferPayload offer) {
    presentOffer(offer);
  }

  void _onNotification(Map<String, dynamic> payload) {
    if (payload['type'] != 'delivery_race_lost') return;
    final orderId = payload['orderId'] as String?;
    if (orderId == null || _pendingOffer?.order.id != orderId) return;
    dismissOffer();
  }

  void _onDeliveryStatus(Map<String, dynamic> payload) {
    final riderId = _attachedRiderId;
    if (riderId == null) return;

    final orderId = payload['orderId'] as String? ?? payload['id'] as String?;
    final orderRaw = payload['order'];
    if (orderRaw is Map<String, dynamic>) {
      try {
        final order = ApiService.riderDeliveryOrderFromJson(orderRaw);
        if (order.riderId != null && order.riderId != riderId) return;
        if (DeliveryStatusUtils.isActive(order.status)) {
          setActiveTrip(order);
          return;
        }
        if (_activeTripOrder?.id == order.id) {
          clearActiveTrip();
        }
        return;
      } catch (e) {
        debugPrint('delivery status parse: $e');
      }
    }

    if (orderId == null || _activeTripOrder?.id != orderId) return;
    final statusRaw = payload['status'] as String?;
    if (statusRaw == null) {
      unawaited(refreshActiveTrip(riderId));
      return;
    }
    final status = _statusFromApi(statusRaw);
    if (!DeliveryStatusUtils.isActive(status)) {
      clearActiveTrip();
    }
  }

  DeliveryStatus _statusFromApi(String raw) {
    switch (raw.toUpperCase()) {
      case 'ACCEPTED':
        return DeliveryStatus.accepted;
      case 'ARRIVED_AT_STORE':
        return DeliveryStatus.arrivedAtStore;
      case 'IN_TRANSIT':
        return DeliveryStatus.inTransit;
      case 'ARRIVED_AT_DESTINATION':
        return DeliveryStatus.arrivedAtDestination;
      case 'IN_PROGRESS':
        return DeliveryStatus.inProgress;
      case 'COMPLETED':
        return DeliveryStatus.completed;
      case 'CANCELLED':
        return DeliveryStatus.cancelled;
      case 'AWAITING_DISPATCH':
        return DeliveryStatus.awaitingDispatch;
      default:
        return DeliveryStatus.pending;
    }
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }
}
