class Bike {
  final String id;
  final String model;
  final String brand;
  final String plate;
  final int currentKm;
  final String oilType;
  final double frontTirePressure;
  final double rearTirePressure;
  final String? photoUrl;

  Bike({
    required this.id,
    required this.model,
    required this.brand,
    required this.plate,
    required this.currentKm,
    required this.oilType,
    required this.frontTirePressure,
    required this.rearTirePressure,
    this.photoUrl,
  });
}
