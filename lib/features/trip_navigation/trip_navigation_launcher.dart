import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_navigator_key.dart';
import '../../models/delivery_order.dart';
import '../../providers/rider_delivery_session_provider.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import 'trip_navigation_experiment.dart';
import 'trip_navigation_screen.dart';

/// Abre a corrida dedicada (Mapbox) após aceite ou retomada.
class TripNavigationLauncher {
  TripNavigationLauncher._();

  static Future<bool?> open(
    BuildContext? context,
    DeliveryOrder initialOrder, {
    bool forceResume = false,
  }) async {
    if (TripNavigationExperiment.activeSessionOpen && !forceResume) {
      return null;
    }
    if (forceResume) {
      TripNavigationExperiment.activeSessionOpen = false;
    }

    RealtimeService.instance.setNavigationMode(
      true,
      orderId: initialOrder.id,
    );

    final session = _readSession(context);
    session?.setActiveTrip(initialOrder);

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      if (context == null || !context.mounted) return null;
      final result = await Navigator.of(context, rootNavigator: true).push<bool>(
        _tripRoute(initialOrder),
      );
      if (result == true) {
        session?.clearActiveTrip();
      }
      return result;
    }

    final result = await navigator.push<bool>(_tripRoute(initialOrder));
    if (result == true) {
      session?.clearActiveTrip();
    }
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

  static MaterialPageRoute<bool> _tripRoute(DeliveryOrder initialOrder) {
    return MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => TripNavigationScreen(
        initialOrder: initialOrder.withoutInternalCode(),
      ),
    );
  }

  static RiderDeliverySessionProvider? _readSession(BuildContext? context) {
    if (context != null && context.mounted) {
      return context.read<RiderDeliverySessionProvider>();
    }
    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return null;
    return rootContext.read<RiderDeliverySessionProvider>();
  }
}
