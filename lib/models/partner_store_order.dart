import 'store_order_item.dart';

/// Pedido da loja virtual na área do lojista (antes/depois do despacho).
class PartnerStoreOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String? deliveryOrderId;
  final String? pickupCode;
  final DateTime? paidAt;
  final DateTime createdAt;
  final List<StoreOrderItem> items;

  const PartnerStoreOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    this.deliveryOrderId,
    this.pickupCode,
    this.paidAt,
    required this.createdAt,
    this.items = const [],
  });

  bool get isPaidAwaitingAccept => status == 'paid';

  bool get hasPickupCode =>
      pickupCode != null && pickupCode!.trim().isNotEmpty;

  factory PartnerStoreOrder.fromJson(Map<String, dynamic> json) {
    double readNum(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    DateTime? readDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final rawItems = json['items'];
    final items = <StoreOrderItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          items.add(
            StoreOrderItem.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
    }

    return PartnerStoreOrder(
      id: json['id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Cliente',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString() ?? '',
      subtotal: readNum(json['subtotal']),
      deliveryFee: readNum(json['deliveryFee']),
      total: readNum(json['total']),
      status: json['status']?.toString() ?? '',
      deliveryOrderId: json['deliveryOrderId']?.toString(),
      pickupCode: json['pickupCode']?.toString(),
      paidAt: readDate(json['paidAt']),
      createdAt: readDate(json['createdAt']) ?? DateTime.now(),
      items: items,
    );
  }
}
