/// URLs de estilo publicadas no Mapbox Studio (opcional).
///
/// Defina via `--dart-define` no build ou substitua os defaults abaixo.
/// Formato: `mapbox://styles/<usuario>/<style-id>`
class MapboxStudioStyleConfig {
  MapboxStudioStyleConfig._();

  static const String day = String.fromEnvironment(
    'MAPBOX_STYLE_DAY',
    defaultValue: '',
  );

  static const String night = String.fromEnvironment(
    'MAPBOX_STYLE_NIGHT',
    defaultValue: '',
  );

  static bool get hasCustomDay => day.trim().isNotEmpty;
  static bool get hasCustomNight => night.trim().isNotEmpty;
  static bool get hasAnyCustom => hasCustomDay || hasCustomNight;
}
