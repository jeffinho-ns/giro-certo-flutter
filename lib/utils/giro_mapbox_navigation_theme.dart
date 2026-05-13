import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Estilos Mapbox alinhados ao Giro Certo (navegacao dia/noite + chrome nativo reduzido).
class GiroMapboxNavigationTheme {
  GiroMapboxNavigationTheme._();

  static const String navigationDay =
      'mapbox://styles/mapbox/navigation-day-v1';
  static const String navigationNight =
      'mapbox://styles/mapbox/navigation-night-v1';

  static bool resolveIsDark(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode;
  }

  static void apply(MapBoxOptions options, {required bool isDarkMode}) {
    options.mapStyleUrlDay = navigationDay;
    options.mapStyleUrlNight = navigationNight;
    options.showReportFeedbackButton = false;
    options.showEndOfRouteFeedback = false;
    options.tilt = isDarkMode ? 52 : 48;
    options.zoom = isDarkMode ? 17.2 : 17;
  }
}
