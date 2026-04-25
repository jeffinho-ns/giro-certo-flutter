/// Alinhado à API: MOTORCYCLE / BICYCLE
enum AppVehicleType {
  motorcycle,
  bicycle,
}

extension AppVehicleTypeApi on AppVehicleType {
  String get apiValue => switch (this) {
        AppVehicleType.motorcycle => 'MOTORCYCLE',
        AppVehicleType.bicycle => 'BICYCLE',
      };

  static AppVehicleType? fromApi(String? raw) {
    if (raw == null) return null;
    final u = raw.toUpperCase();
    if (u == 'BICYCLE') return AppVehicleType.bicycle;
    return AppVehicleType.motorcycle;
  }
}
