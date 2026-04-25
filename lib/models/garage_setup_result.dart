import 'motorcycle_model.dart';
import 'vehicle_type.dart';

/// Resultado da tela "Escolha sua marca" (moto com catálogo ou bicicleta manual).
class GarageSetupResult {
  final AppVehicleType mode;
  final MotorcycleModel? motorcycle;
  final String? resolvedImagePath;
  final String brand;
  final String model;
  final String plate;
  final int currentKm;
  final String oilType;
  final double frontTirePressure;
  final double rearTirePressure;

  /// Só preenchido quando [mode] é bicicleta.
  final String? bicycleAro;
  final String? bicycleCor;
  final String? bicycleObservacao;

  const GarageSetupResult({
    required this.mode,
    this.motorcycle,
    this.resolvedImagePath,
    required this.brand,
    required this.model,
    required this.plate,
    required this.currentKm,
    required this.oilType,
    required this.frontTirePressure,
    required this.rearTirePressure,
    this.bicycleAro,
    this.bicycleCor,
    this.bicycleObservacao,
  });
}
