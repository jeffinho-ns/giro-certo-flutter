import 'dart:math' as math;

enum DeliveryStatus {
  pending,      // Aguardando motociclista
  accepted,     // Aceito por um motociclista
  inProgress,   // Em andamento
  completed,    // Concluído
  cancelled,    // Cancelado
}

enum DeliveryPriority {
  low,      // Baixa
  normal,   // Normal
  high,     // Alta
  urgent,   // Urgente
}

class DeliveryOrder {
  final String id;
  final String storeId;
  final String storeName;
  final String storeAddress;
  final double storeLatitude;
  final double storeLongitude;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String? recipientName;
  final String? recipientPhone;
  final String? notes; // Observações do pedido
  final double value; // Valor do pedido
  final double deliveryFee; // Taxa de entrega
  final DeliveryStatus status;
  final DeliveryPriority priority;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? riderId; // ID do motociclista que aceitou
  final String? riderName; // Nome do motociclista
  final double? distance; // Distância em km
  final int? estimatedTime; // Tempo estimado em minutos

  DeliveryOrder({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.storeAddress,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.recipientName,
    this.recipientPhone,
    this.notes,
    required this.value,
    required this.deliveryFee,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.riderId,
    this.riderName,
    this.distance,
    this.estimatedTime,
  });

  // Calcula a distância total da corrida (loja -> entrega)
  double get totalDistance {
    return _calculateDistance(
      storeLatitude,
      storeLongitude,
      deliveryLatitude,
      deliveryLongitude,
    );
  }

  // Calcula distância da loja até o usuário atual
  double distanceFromStore(double userLat, double userLng) {
    return _calculateDistance(storeLatitude, storeLongitude, userLat, userLng);
  }

  // Calcula distância da entrega até o usuário atual
  double distanceFromDelivery(double userLat, double userLng) {
    return _calculateDistance(deliveryLatitude, deliveryLongitude, userLat, userLng);
  }

  // Calcula distância total que o motociclista percorrerá (usuário -> loja -> entrega)
  double totalDistanceForRider(double riderLat, double riderLng) {
    final toStore = _calculateDistance(riderLat, riderLng, storeLatitude, storeLongitude);
    final storeToDelivery = totalDistance;
    return toStore + storeToDelivery;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  // Valor total (pedido + taxa de entrega)
  double get totalValue => value + deliveryFee;

  // Retorna uma cópia com status atualizado
  DeliveryOrder copyWith({
    DeliveryStatus? status,
    String? riderId,
    String? riderName,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return DeliveryOrder(
      id: id,
      storeId: storeId,
      storeName: storeName,
      storeAddress: storeAddress,
      storeLatitude: storeLatitude,
      storeLongitude: storeLongitude,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      notes: notes,
      value: value,
      deliveryFee: deliveryFee,
      status: status ?? this.status,
      priority: priority,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      distance: distance,
      estimatedTime: estimatedTime,
    );
  }
}

