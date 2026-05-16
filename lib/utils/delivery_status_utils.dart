import '../models/delivery_order.dart';

class DeliveryStatusUtils {
  static bool isPending(DeliveryStatus status) {
    return status == DeliveryStatus.pending;
  }

  static bool isAwaitingDispatch(DeliveryStatus status) {
    return status == DeliveryStatus.awaitingDispatch;
  }

  static bool isActive(DeliveryStatus status) {
    return status == DeliveryStatus.accepted ||
        status == DeliveryStatus.arrivedAtStore ||
        status == DeliveryStatus.inTransit ||
        status == DeliveryStatus.arrivedAtDestination ||
        status == DeliveryStatus.inProgress;
  }

  static bool isCompleted(DeliveryStatus status) {
    return status == DeliveryStatus.completed;
  }

  /// Pré‑pago: só em «aguardando despacho». Pós‑pago / captura: também durante corrida ativa.
  static bool allowsStorePaymentCheckout(
    DeliveryStatus status,
    String? collectionMode,
  ) {
    if (status == DeliveryStatus.completed || status == DeliveryStatus.cancelled) {
      return false;
    }
    final raw = collectionMode?.trim();
    final m = (raw == null || raw.isEmpty) ? 'prepaid' : raw;
    if (m == 'prepaid') {
      return status == DeliveryStatus.awaitingDispatch;
    }
    return status == DeliveryStatus.awaitingDispatch || isActive(status);
  }
}
