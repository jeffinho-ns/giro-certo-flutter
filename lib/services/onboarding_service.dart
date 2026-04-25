import 'package:shared_preferences/shared_preferences.dart';
import '../models/pilot_profile.dart';

class OnboardingService {
  static const String _stepKey = 'onboarding_step';
  static const String _completedKey = 'onboarding_completed';
  static const String _pilotTypeKey = 'onboarding_pilot_type';
  static const String _deliveryStatusKey = 'delivery_profile_status';
  static const String _motorcycleIdKey = 'onboarding_motorcycle_id';
  static const String _motorcycleImageKey = 'onboarding_motorcycle_image';
  static const String _isBicycleKey = 'onboarding_is_bicycle';
  static const String _bicycleBrandKey = 'onboarding_bicycle_brand';
  static const String _bicycleAroKey = 'onboarding_bicycle_aro';
  static const String _bicycleCorKey = 'onboarding_bicycle_cor';
  static const String _bicycleObsKey = 'onboarding_bicycle_obs';
  static const String _lastDeliveryRegStatusKey = 'last_delivery_reg_status';

  /// ID fictício usado no fluxo de bicicleta (sem modelo no catálogo).
  static const String bicycleCatalogId = 'GIRO_BICICLETA';

  static Future<void> saveStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepKey, step);
  }

  static Future<int?> getSavedStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepKey);
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    await prefs.remove(_stepKey);
  }

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> savePilotType(PilotProfileType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pilotTypeKey, type.apiValue);
  }

  static Future<PilotProfileType?> getPilotType() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pilotTypeKey);
    if (stored == null) return null;
    return PilotProfileType.values.firstWhere(
      (type) => type.apiValue == stored,
      orElse: () => PilotProfileType.diario,
    );
  }

  static Future<void> saveDeliveryStatus(
      DeliveryModerationStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deliveryStatusKey, status.label);
  }

  static Future<DeliveryModerationStatus?> getDeliveryStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_deliveryStatusKey);
    if (stored == null) return null;
    return DeliveryModerationStatusExtension.fromString(stored);
  }

  static Future<void> saveMotorcycleSelection({
    required String motorcycleId,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_motorcycleIdKey, motorcycleId);
    if (imagePath != null) {
      await prefs.setString(_motorcycleImageKey, imagePath);
    } else {
      await prefs.remove(_motorcycleImageKey);
    }
  }

  static Future<String?> getSelectedMotorcycleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_motorcycleIdKey);
  }

  static Future<String?> getSelectedMotorcycleImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_motorcycleImageKey);
  }

  static Future<void> saveBicycleGarageInfo({
    required String brand,
    required String aro,
    required String cor,
    required String observacao,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isBicycleKey, true);
    await prefs.setString(_bicycleBrandKey, brand);
    await prefs.setString(_bicycleAroKey, aro);
    await prefs.setString(_bicycleCorKey, cor);
    await prefs.setString(_bicycleObsKey, observacao);
  }

  static Future<void> clearBicycleGarageInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isBicycleKey);
    await prefs.remove(_bicycleBrandKey);
    await prefs.remove(_bicycleAroKey);
    await prefs.remove(_bicycleCorKey);
    await prefs.remove(_bicycleObsKey);
  }

  static Future<bool> isBicycleFlow() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isBicycleKey) ?? false;
  }

  static Future<({String brand, String aro, String cor, String obs})?> getBicycleGarageInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_isBicycleKey) != true) return null;
    final b = prefs.getString(_bicycleBrandKey) ?? '';
    return (
      brand: b,
      aro: prefs.getString(_bicycleAroKey) ?? '',
      cor: prefs.getString(_bicycleCorKey) ?? '',
      obs: prefs.getString(_bicycleObsKey) ?? '',
    );
  }

  static Future<void> setLastKnownDeliveryRegStatus(String? status) async {
    final prefs = await SharedPreferences.getInstance();
    if (status == null || status.isEmpty) {
      await prefs.remove(_lastDeliveryRegStatusKey);
    } else {
      await prefs.setString(_lastDeliveryRegStatusKey, status);
    }
  }

  static Future<String?> getLastKnownDeliveryRegStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDeliveryRegStatusKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stepKey);
    await prefs.remove(_completedKey);
    await prefs.remove(_pilotTypeKey);
    await prefs.remove(_deliveryStatusKey);
    await prefs.remove(_motorcycleIdKey);
    await prefs.remove(_motorcycleImageKey);
    await clearBicycleGarageInfo();
    await prefs.remove(_lastDeliveryRegStatusKey);
  }

  /// Limpeza obrigatória no logout para evitar vazamento entre contas.
  static Future<void> clearForLogout() async {
    await clear();
  }
}
