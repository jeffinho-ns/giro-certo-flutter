import 'package:geolocator/geolocator.dart';

/// Regras de proximidade para etapas da corrida.
class DeliveryGeofence {
  DeliveryGeofence._();

  static const double storeArrivalMaxMeters = 150;

  static double? distanceMeters({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    return Geolocator.distanceBetween(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }
}

enum ConfirmArrivalResult {
  confirmed,
  tooFarFromStore,
  locationUnavailable,
  failed,
}
