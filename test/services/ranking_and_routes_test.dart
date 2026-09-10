import 'package:flutter_test/flutter_test.dart';
import 'package:giro_certo/models/delivery_order.dart';
import 'package:giro_certo/models/rider_ranking_entry.dart';
import 'package:giro_certo/services/routes_service.dart';

void main() {
  group('RiderRankingEntry', () {
    test('lê completedCount e nome da API', () {
      final entry = RiderRankingEntry.fromJson({
        'userId': 'u1',
        'name': 'Ana',
        'completedCount': 12,
        'rating': 4.5,
      }, 0);
      expect(entry.id, 'u1');
      expect(entry.name, 'Ana');
      expect(entry.completedCount, 12);
      expect(entry.rating, 4.5);
    });

    test('aceita aliases de entregas', () {
      final entry = RiderRankingEntry.fromJson({
        'riderName': 'Bruno',
        'deliveries': 3,
      }, 2);
      expect(entry.name, 'Bruno');
      expect(entry.completedCount, 3);
      expect(entry.id, '2');
    });
  });

  group('RoutesService.fromCompletedOrders', () {
    test('monta histórico e calor a partir de entregas reais', () {
      final order = DeliveryOrder(
        id: 'o1',
        storeId: 's1',
        storeName: 'Padaria Central',
        storeAddress: 'Rua A',
        storeLatitude: -23.55,
        storeLongitude: -46.63,
        deliveryAddress: 'Rua B, 10',
        deliveryLatitude: -23.56,
        deliveryLongitude: -46.64,
        value: 40,
        deliveryFee: 8,
        status: DeliveryStatus.completed,
        priority: DeliveryPriority.normal,
        createdAt: DateTime(2026, 9, 1, 10),
        acceptedAt: DateTime(2026, 9, 1, 10, 5),
        completedAt: DateTime(2026, 9, 1, 10, 25),
        distance: 3.2,
      );

      final data = RoutesService.fromCompletedOrders(
        [order],
        isDelivery: true,
        fallbackLat: -23.55,
        fallbackLng: -46.63,
      );

      expect(data.isEmpty, isFalse);
      expect(data.history, hasLength(1));
      expect(data.history.first.originLabel, 'Padaria Central');
      expect(data.history.first.distanceKm, 3.2);
      expect(data.regions.single.name, 'Padaria Central');
      expect(data.regions.single.visitCount, 1);
      expect(data.heatmapPoints, hasLength(2));
    });

    test('lista vazia vira empty honesto', () {
      final data = RoutesData.empty(
        isDelivery: false,
        centerLatitude: -23.55,
        centerLongitude: -46.63,
      );
      expect(data.isEmpty, isTrue);
      expect(data.history, isEmpty);
    });
  });
}
