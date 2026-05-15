import 'package:geolocator/geolocator.dart';

/// Regras de proximidade para etapas da corrida.
class DeliveryGeofence {
  DeliveryGeofence._();

  /// MVP / testes: quando `false`, o motociclista pode confirmar chegada na loja sem validar GPS.
  static const bool requireStoreArrivalProximity = false;

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
