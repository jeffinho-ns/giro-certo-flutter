import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

/// Pedidos que o motociclista recusou explicitamente — não voltam a aparecer na lista nem no modal.
class RejectedDeliveryOffersStore {
  RejectedDeliveryOffersStore._();

  static const String _prefix = 'delivery_rejected_order_ids_v1:';
  static const int _maxIds = 300;

  static String _key(String userId) => '$_prefix$userId';

  static Future<Set<String>> loadForUser(String userId) async {
    if (userId.isEmpty) return <String>{};
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key(userId));
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((e) => e.isNotEmpty).toSet();
  }

  static Future<void> add(String userId, String orderId) async {
    if (userId.isEmpty || orderId.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final existing = await loadForUser(userId);
    final linked = LinkedHashSet<String>.from(existing);
    linked.remove(orderId);
    linked.add(orderId);
    while (linked.length > _maxIds) {
      linked.remove(linked.first);
    }
    await p.setString(_key(userId), linked.join(','));
  }
}
