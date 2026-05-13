import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

/// Aplica chrome imersivo (edge-to-edge) durante a corrida e restaura ao sair.
class TripNavigationImmersiveScope extends StatefulWidget {
  const TripNavigationImmersiveScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<TripNavigationImmersiveScope> createState() =>
      _TripNavigationImmersiveScopeState();
}

class _TripNavigationImmersiveScopeState extends State<TripNavigationImmersiveScope> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [
        SystemUiOverlay.top,
        SystemUiOverlay.bottom,
      ],
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: widget.child,
    );
  }
}
