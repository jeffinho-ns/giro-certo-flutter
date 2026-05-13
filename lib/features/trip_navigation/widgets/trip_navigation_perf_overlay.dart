import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../trip_navigation_performance.dart';

class TripNavigationPerfOverlay extends StatelessWidget {
  const TripNavigationPerfOverlay({
    super.key,
    required this.performance,
  });

  final TripNavigationPerformance performance;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final routeBuild = performance.routeBuildDurationMs;
    final lines = <String>[
      'mapView ${performance.mapViewReadyMs ?? '-'} ms',
      'rota ${routeBuild ?? '-'} ms',
      'ativa ${performance.navigationRunningMs ?? '-'} ms',
      'jank ${performance.slowFrameCount} (max ${performance.slowFrameMaxMs.toStringAsFixed(0)} ms)',
    ];

    return Positioned(
      left: 12,
      bottom: 120,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: lines
                  .map(
                    (line) => Text(
                      line,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
