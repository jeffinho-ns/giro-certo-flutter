import 'package:flutter_test/flutter_test.dart';
import 'package:giro_certo/data/manual/manual_models.dart';
import 'package:giro_certo/models/bike.dart';
import 'package:giro_certo/services/manual_content_service.dart';

Bike _bike({required String brand, required String model}) {
  return Bike(
    id: 'test-1',
    brand: brand,
    model: model,
    plate: 'ABC1D23',
    currentKm: 10000,
    oilType: '10W-40',
    frontTirePressure: 2.5,
    rearTirePressure: 2.8,
  );
}

void main() {
  final service = ManualContentService(
    bikesLoader: () async => [],
  );

  test('resolve exact model CG 160', () {
    final content = service.resolveForBike(
      _bike(brand: 'Honda', model: 'CG 160'),
    );
    expect(content.hasBike, isTrue);
    expect(content.matchLevel, ManualContentMatchLevel.exactModel);
    expect(content.bikeLabel, 'Honda CG 160');
    expect(content.modelTips.length, greaterThanOrEqualTo(3));
    expect(content.officialLinks, isNotEmpty);
  });

  test('resolve Bros alias to NXR/Bros 160', () {
    final content = service.resolveForBike(
      _bike(brand: 'Honda', model: 'Bros 160'),
    );
    expect(content.matchLevel, ManualContentMatchLevel.exactModel);
    expect(
      content.modelTips.any((t) => t.toLowerCase().contains('bros')),
      isTrue,
    );
  });

  test('resolve brand fallback for unknown Honda model', () {
    final content = service.resolveForBike(
      _bike(brand: 'Honda', model: 'CBR 1000RR'),
    );
    expect(content.hasBike, isTrue);
    expect(content.matchLevel, ManualContentMatchLevel.brand);
    expect(content.officialLinks, isNotEmpty);
  });

  test('resolve displacement class for unknown brand trail', () {
    final content = service.resolveForBike(
      _bike(brand: 'MarcaX', model: 'Trail 250'),
    );
    expect(content.matchLevel, ManualContentMatchLevel.displacementClass);
    expect(content.modelTips, isNotEmpty);
  });

  test('empty when no bike', () async {
    final bundle = await service.loadBundle();
    expect(bundle.bikeContent.hasBike, isFalse);
    expect(bundle.bikeContent.matchLevel, ManualContentMatchLevel.none);
    expect(bundle.beginnerGuides.length, 5);
    expect(bundle.parts, isNotEmpty);
  });

  test('Yamaha NMAX exact match', () {
    final content = service.resolveForBike(
      _bike(brand: 'Yamaha', model: 'NMAX 160'),
    );
    expect(content.matchLevel, ManualContentMatchLevel.exactModel);
    expect(content.officialLinks.first.url, contains('yamaha'));
  });

  test('Suzuki Yes 125 curated even if not in image catalog', () {
    final content = service.resolveForBike(
      _bike(brand: 'Suzuki', model: 'Yes 125'),
    );
    expect(content.matchLevel, ManualContentMatchLevel.exactModel);
    expect(content.officialLinks.any((l) => l.url.contains('suzuki')), isTrue);
  });
}
