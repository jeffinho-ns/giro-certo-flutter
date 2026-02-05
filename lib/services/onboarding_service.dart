import 'package:shared_preferences/shared_preferences.dart';
import '../models/pilot_profile.dart';

class OnboardingService {
  static const String _stepKey = 'onboarding_step';
  static const String _completedKey = 'onboarding_completed';
  static const String _pilotTypeKey = 'onboarding_pilot_type';
  static const String _deliveryStatusKey = 'delivery_profile_status';
  static const String _motorcycleIdKey = 'onboarding_motorcycle_id';
  static const String _motorcycleImageKey = 'onboarding_motorcycle_image';

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

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stepKey);
    await prefs.remove(_completedKey);
    await prefs.remove(_pilotTypeKey);
    await prefs.remove(_deliveryStatusKey);
    await prefs.remove(_motorcycleIdKey);
    await prefs.remove(_motorcycleImageKey);
  }
}
