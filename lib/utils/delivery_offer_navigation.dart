import 'dart:async';

import 'package:provider/provider.dart';

import '../app_navigator_key.dart';
import '../providers/navigation_provider.dart';
import '../providers/rider_delivery_session_provider.dart';

/// Com a app em primeiro plano: abre o modal de oferta (som no Pipcar), sem notificação nativa.
Future<void> presentDeliveryOfferWhileAppForeground(String orderId) async {
  final trimmed = orderId.trim();
  if (trimmed.isEmpty) return;
  final root = appNavigatorKey.currentContext;
  if (root == null) return;
  final session = Provider.of<RiderDeliverySessionProvider>(root, listen: false);
  session.scheduleDeepLinkOffer(trimmed);
  await Future<void>.delayed(const Duration(milliseconds: 120));
  await session.presentOfferFromPush(trimmed);
}

/// Após toque na notificação de nova corrida: vai ao hub (mapa) e abre o modal de aceitar.
Future<void> openDeliveryOfferFromNotificationTap(String orderId) async {
  final trimmed = orderId.trim();
  if (trimmed.isEmpty) return;

  final root = appNavigatorKey.currentContext;
  if (root == null) return;

  final nav = Provider.of<NavigationProvider>(root, listen: false);
  final session = Provider.of<RiderDeliverySessionProvider>(root, listen: false);
  nav.navigateToRiderOrPartnerHub();
  session.scheduleDeepLinkOffer(trimmed);

  await Future<void>.delayed(const Duration(milliseconds: 400));
  session.scheduleDeepLinkOffer(trimmed);
}
