import '../../models/delivery_order.dart';

class DeliveryOfferPayload {
  const DeliveryOfferPayload({
    required this.order,
    required this.expiresInSeconds,
    this.distanceToStoreKm,
    this.routeDistanceKm,
  });

  final DeliveryOrder order;
  final int expiresInSeconds;
  final double? distanceToStoreKm;
  final double? routeDistanceKm;
}
