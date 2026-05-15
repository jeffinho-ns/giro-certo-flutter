import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/trip_navigation/trip_navigation_experiment.dart';
import '../models/delivery_offer_payload.dart';
import '../models/delivery_order.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../services/rejected_delivery_offers_store.dart';
import '../utils/delivery_status_utils.dart';

/// Ofertas em tempo real e corrida ativa do entregador (global no app).
class RiderDeliverySessionProvider extends ChangeNotifier {
  DeliveryOfferPayload? _pendingOffer;
  DeliveryOrder? _activeTripOrder;
  StreamSubscription<DeliveryOfferPayload>? _offerSubscription;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliveryStatusSubscription;
  Timer? _pendingOfferPollTimer;
  final Set<String> _dismissedOfferOrderIds = <String>{};
  String? _attachedRiderId;
  bool _isDeliveryPilot = false;
  bool _isDeliveryApproved = true;
  String? _pendingDeepLinkOrderId;

  DeliveryOfferPayload? get pendingOffer => _pendingOffer;
  DeliveryOrder? get activeTripOrder => _activeTripOrder;

  /// Recusas explícitas (persistidas) + supressão de sessão (ex.: corrida perdida).
  bool isOrderHiddenFromRiderLists(String orderId) =>
      _dismissedOfferOrderIds.contains(orderId);

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
      if (_pendingDeepLinkOrderId != null) {
        unawaited(_flushDeepLinkOffer());
      }
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

    _pendingOfferPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_syncPendingOffersFromApi()),
    );

    unawaited(_bootstrapAfterAttach(riderId));
  }

  Future<void> _bootstrapAfterAttach(String riderId) async {
    await _hydrateRejectedIdsFromStorage(riderId);
    await refreshActiveTrip(riderId);
    if (_pendingDeepLinkOrderId != null) {
      await _flushDeepLinkOffer();
    }
    await _syncPendingOffersFromApi();
  }

  Future<void> _hydrateRejectedIdsFromStorage(String riderId) async {
    final fromDisk = await RejectedDeliveryOffersStore.loadForUser(riderId);
    _dismissedOfferOrderIds
      ..clear()
      ..addAll(fromDisk);
    notifyListeners();
  }

  /// Abrir oferta após toque em notificação (antes do attach pode ficar em fila).
  void scheduleDeepLinkOffer(String orderId) {
    if (orderId.isEmpty) return;
    _pendingDeepLinkOrderId = orderId;
    if (_attachedRiderId != null && _offerSubscription != null) {
      unawaited(_flushDeepLinkOffer());
    }
  }

  Future<void> _flushDeepLinkOffer() async {
    final id = _pendingDeepLinkOrderId;
    if (id == null) return;
    _pendingDeepLinkOrderId = null;
    await presentOfferFromPush(id);
  }

  /// Carrega o pedido e mostra o modal de aceitar (ex.: push em background).
  Future<void> presentOfferFromPush(String orderId) async {
    if (_attachedRiderId == null) return;
    if (!_canReceiveOffers) return;
    if (TripNavigationExperiment.activeSessionOpen) return;
    if (_activeTripOrder != null) return;
    if (_dismissedOfferOrderIds.contains(orderId)) return;
    try {
      final order = await ApiService.getDeliveryOrder(
        orderId,
        hidePickupCode: true,
      );
      if (!DeliveryStatusUtils.isPending(order.status)) return;
      if (order.riderId != null) return;
      if (_dismissedOfferOrderIds.contains(order.id)) return;
      _presentOfferFromOrder(order);
    } catch (e) {
      debugPrint('presentOfferFromPush: $e');
    }
  }

  void detach() {
    _offerSubscription?.cancel();
    _notificationSubscription?.cancel();
    _deliveryStatusSubscription?.cancel();
    _pendingOfferPollTimer?.cancel();
    _offerSubscription = null;
    _notificationSubscription = null;
    _deliveryStatusSubscription = null;
    _pendingOfferPollTimer = null;
    _attachedRiderId = null;
    _pendingDeepLinkOrderId = null;
    _pendingOffer = null;
    _activeTripOrder = null;
    _dismissedOfferOrderIds.clear();
    notifyListeners();
  }

  void presentOffer(DeliveryOfferPayload offer) {
    if (!_canReceiveOffers) return;
    if (TripNavigationExperiment.activeSessionOpen) return;
    if (_activeTripOrder != null) return;
    if (_dismissedOfferOrderIds.contains(offer.order.id)) return;
    if (_pendingOffer?.order.id == offer.order.id) return;
    _pendingOffer = offer;
    notifyListeners();
  }

  /// Fecha o modal sem marcar como recusada (aceitar, limpezas internas).
  void clearPendingOffer() {
    if (_pendingOffer == null) return;
    _pendingOffer = null;
    notifyListeners();
  }

  /// Motociclista recusou: não mostrar mais este pedido (lista + modal).
  Future<void> rejectOffer() async {
    final riderId = _attachedRiderId;
    final current = _pendingOffer;
    if (current != null && riderId != null) {
      try {
        await RejectedDeliveryOffersStore.add(riderId, current.order.id);
      } catch (e) {
        debugPrint('rejectOffer persist: $e');
      }
      _dismissedOfferOrderIds.add(current.order.id);
    }
    _pendingOffer = null;
    notifyListeners();
  }

  /// Outro aceitou / perdeu a corrida: esconder só na sessão atual (não persiste).
  void suppressOfferForSession(String orderId) {
    if (orderId.isEmpty) return;
    _dismissedOfferOrderIds.add(orderId);
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
    // Ofertas globais: qualquer motociclista autenticado (sem loja) pode receber.
    // Cadastro delivery em analise nao bloqueia o modal no MVP de testes.
    return true;
  }

  void _onOffer(DeliveryOfferPayload offer) {
    presentOffer(offer);
  }

  void _onNotification(Map<String, dynamic> payload) {
    if (payload['type'] != 'delivery_race_lost') return;
    final orderId = payload['orderId'] as String?;
    if (orderId == null || _pendingOffer?.order.id != orderId) return;
    suppressOfferForSession(orderId);
    clearPendingOffer();
  }

  void _onDeliveryStatus(Map<String, dynamic> payload) {
    final riderId = _attachedRiderId;
    if (riderId == null) return;

    final orderRaw = payload['order'];
    if (orderRaw is Map<String, dynamic>) {
      try {
        final order = ApiService.riderDeliveryOrderFromJson(orderRaw);
        if (order.riderId != null && order.riderId != riderId) return;
        if (DeliveryStatusUtils.isActive(order.status)) {
          setActiveTrip(order);
          return;
        }
        if (DeliveryStatusUtils.isPending(order.status) &&
            order.riderId == null) {
          _presentOfferFromOrder(order);
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

    final orderId = payload['orderId'] as String? ?? payload['id'] as String?;
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

  Future<void> _syncPendingOffersFromApi() async {
    if (!_canReceiveOffers) return;
    if (_pendingOffer != null || _activeTripOrder != null) return;

    try {
      final orders = await ApiService.getDeliveryOrders(
        status: 'pending',
        limit: 8,
        hidePickupCode: true,
      );
      for (final order in orders) {
        if (!DeliveryStatusUtils.isPending(order.status)) continue;
        if (_dismissedOfferOrderIds.contains(order.id)) continue;
        _presentOfferFromOrder(order);
        return;
      }
    } catch (e) {
      debugPrint('Falha ao sincronizar ofertas pendentes: $e');
    }
  }

  void _presentOfferFromOrder(DeliveryOrder order) {
    presentOffer(
      DeliveryOfferPayload(
        order: order.withoutInternalCode(),
        expiresInSeconds: 15,
        distanceToStoreKm: null,
        routeDistanceKm: order.totalDistance,
      ),
    );
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
