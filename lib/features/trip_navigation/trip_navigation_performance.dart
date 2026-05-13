import 'package:flutter/foundation.dart';

/// Marcos de fluidez da sessao de navegacao (debug / telemetria local).
class TripNavigationPerformance {
  TripNavigationPerformance() {
    _sessionStopwatch.start();
    sessionStartedAt = DateTime.now();
  }

  final Stopwatch _sessionStopwatch = Stopwatch();
  DateTime? sessionStartedAt;
  int? mapViewReadyMs;
  int? routeBuildStartedMs;
  int? routeBuiltMs;
  int? navigationRunningMs;
  int slowFrameCount = 0;
  double slowFrameMaxMs = 0;

  void markMapViewReady() {
    mapViewReadyMs ??= _sessionStopwatch.elapsedMilliseconds;
  }

  void markRouteBuildStarted() {
    routeBuildStartedMs ??= _sessionStopwatch.elapsedMilliseconds;
  }

  void markRouteBuilt() {
    routeBuiltMs ??= _sessionStopwatch.elapsedMilliseconds;
  }

  void markNavigationRunning() {
    navigationRunningMs ??= _sessionStopwatch.elapsedMilliseconds;
  }

  void recordSlowFrame(double frameMs) {
    if (frameMs < 18) return;
    slowFrameCount++;
    if (frameMs > slowFrameMaxMs) slowFrameMaxMs = frameMs;
  }

  int? get routeBuildDurationMs {
    if (routeBuildStartedMs == null || routeBuiltMs == null) return null;
    return routeBuiltMs! - routeBuildStartedMs!;
  }

  void logSummary({String? orderId}) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('TripNav perf');
    if (orderId != null) buffer.write(' order=$orderId');
    buffer.write(
      ' | mapView=${mapViewReadyMs ?? '-'}ms'
      ' routeBuild=${routeBuildDurationMs ?? '-'}ms'
      ' running=${navigationRunningMs ?? '-'}ms'
      ' slowFrames=$slowFrameCount'
      ' maxSlow=${slowFrameMaxMs.toStringAsFixed(1)}ms',
    );
    debugPrint(buffer.toString());
  }
}
