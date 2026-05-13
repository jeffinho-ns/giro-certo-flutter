import 'package:flutter/material.dart';

import '../../models/delivery_order.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import 'trip_navigation_experiment.dart';
import 'trip_navigation_screen.dart';

/// Abre a corrida dedicada (Mapbox) após aceite ou retomada.
class TripNavigationLauncher {
  TripNavigationLauncher._();

  static Future<bool?> open(
    BuildContext context,
    DeliveryOrder initialOrder,
  ) async {
    if (TripNavigationExperiment.activeSessionOpen) {
      return null;
    }

    RealtimeService.instance.setNavigationMode(
      true,
      orderId: initialOrder.id,
    );

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TripNavigationScreen(
          initialOrder: initialOrder.withoutInternalCode(),
        ),
      ),
    );

    if (!context.mounted) return result;
    return result;
  }

  static Future<bool?> acceptAndOpen(
    BuildContext context, {
    required DeliveryOrder order,
    required String riderId,
    required String riderName,
  }) async {
    final accepted = await ApiService.acceptOrder(
      order.id,
      riderId: riderId,
      riderName: riderName,
    );
    if (!context.mounted) return null;
    return open(context, accepted);
  }
}
