import '../models/delivery_order.dart';

class DeliveryStatusUtils {
  static bool isPending(DeliveryStatus status) {
    return status == DeliveryStatus.pending;
  }

  static bool isActive(DeliveryStatus status) {
    return status == DeliveryStatus.accepted ||
        status == DeliveryStatus.arrivedAtStore ||
        status == DeliveryStatus.inTransit ||
        status == DeliveryStatus.inProgress;
  }

  static bool isCompleted(DeliveryStatus status) {
    return status == DeliveryStatus.completed;
  }
}
