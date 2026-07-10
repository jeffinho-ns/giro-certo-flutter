import '../data/manual/beginner_guides.dart';
import '../data/manual/curated_models.dart';
import '../data/manual/manual_models.dart';
import '../data/manual/parts_info.dart';
import '../models/bike.dart';
import '../models/motorcycle_model.dart';
import 'api_service.dart';
import 'motorcycle_data_service.dart';

/// Resolve conteúdo do Guia do piloto a partir da moto da garagem.
///
/// Ordem de matching:
/// 1. Modelo exato (ou alias) no catálogo curado
/// 2. Dicas + links da marca
/// 3. Classe por cilindrada / tipo (street, scooter, trail, naked)
/// 4. Fallback genérico
class ManualContentService {
  ManualContentService({
    Future<List<Bike>> Function()? bikesLoader,
    List<MotorcycleModel> Function()? catalogLoader,
  })  : _bikesLoader = bikesLoader ?? ApiService.getMyBikes,
        _catalogLoader =
            catalogLoader ?? MotorcycleDataService.getAllMotorcycles;

  final Future<List<Bike>> Function() _bikesLoader;
  final List<MotorcycleModel> Function() _catalogLoader;

  Future<ManualBundle> loadBundle({Bike? preferredBike}) async {
    Bike? bike = preferredBike;
    if (bike == null) {
      try {
        final bikes = await _bikesLoader();
        bike = bikes.isNotEmpty ? bikes.first : null;
      } catch (_) {
        bike = null;
      }
    }

    final bikeContent = resolveForBike(bike);
    return ManualBundle(
      bikeContent: bikeContent,
      beginnerGuides: kBeginnerGuides,
      parts: kPartsInfo,
    );
  }

  ManualBikeContent resolveForBike(Bike? bike) {
    if (bike == null || bike.isBicycle || _isPlaceholderBike(bike)) {
      return ManualBikeContent.empty();
    }

    final brand = bike.brand.trim();
    final model = bike.model.trim();
    if (brand.isEmpty && model.isEmpty) {
      return ManualBikeContent.empty();
    }

    final label = _bikeLabel(brand, model);
    final catalogMatch = _findInCatalog(brand, model);
    final cc = catalogMatch != null
        ? _parseCc(catalogMatch.displacement)
        : _guessCcFromModel(model);

    final exact = _findExactModel(brand, model);
    if (exact != null) {
      final brandEntry = _findBrand(exact.brand);
      return ManualBikeContent(
        bikeLabel: label,
        brand: exact.brand,
        model: exact.model,
        displacementCc: exact.displacementCc,
        vehicleClass: exact.vehicleClass,
        matchLevel: ManualContentMatchLevel.exactModel,
        schedule: exact.schedule,
        modelTips: exact.tips,
        officialLinks: brandEntry?.links ?? _genericBrandLinks(exact.brand),
        hasBike: true,
      );
    }

    final brandEntry = _findBrand(brand);
    if (brandEntry != null) {
      final classEntry = _resolveClass(cc, model);
      return ManualBikeContent(
        bikeLabel: label,
        brand: brandEntry.brand,
        model: model,
        displacementCc: cc,
        vehicleClass: classEntry.id,
        matchLevel: ManualContentMatchLevel.brand,
        schedule: classEntry.schedule,
        modelTips: [
          ...brandEntry.tips,
          ...classEntry.tips.take(3),
        ],
        officialLinks: brandEntry.links,
        hasBike: true,
      );
    }

    final classEntry = _resolveClass(cc, model);
    if (classEntry.id != 'generic') {
      return ManualBikeContent(
        bikeLabel: label,
        brand: brand.isEmpty ? null : brand,
        model: model.isEmpty ? null : model,
        displacementCc: cc,
        vehicleClass: classEntry.id,
        matchLevel: ManualContentMatchLevel.displacementClass,
        schedule: classEntry.schedule,
        modelTips: classEntry.tips,
        officialLinks: _genericBrandLinks(brand),
        hasBike: true,
      );
    }

    final generic = kClassEntries.firstWhere((c) => c.id == 'generic');
    return ManualBikeContent(
      bikeLabel: label,
      brand: brand.isEmpty ? null : brand,
      model: model.isEmpty ? null : model,
      displacementCc: cc,
      vehicleClass: generic.id,
      matchLevel: ManualContentMatchLevel.generic,
      schedule: generic.schedule,
      modelTips: generic.tips,
      officialLinks: _genericBrandLinks(brand),
      hasBike: true,
    );
  }

  // --- helpers ---

  bool _isPlaceholderBike(Bike bike) {
    if (bike.id == 'delivery-registration-fallback') return true;
    final brand = bike.brand.toLowerCase();
    final model = bike.model.toLowerCase();
    return model == 'delivery' && (brand == 'moto' || brand == 'bicicleta');
  }

  String _bikeLabel(String brand, String model) {
    if (brand.isNotEmpty && model.isNotEmpty) return '$brand $model';
    if (model.isNotEmpty) return model;
    return brand;
  }

  MotorcycleModel? _findInCatalog(String brand, String model) {
    final catalog = _catalogLoader();
    final nb = _norm(brand);
    final nm = _norm(model);
    for (final m in catalog) {
      if (_norm(m.brand) == nb && _norm(m.model) == nm) return m;
      if (_norm(m.model) == nm) return m;
      if (nm.isNotEmpty && _norm(m.model).contains(nm)) return m;
      if (nm.isNotEmpty && nm.contains(_norm(m.model))) return m;
    }
    return null;
  }

  ManualModelEntry? _findExactModel(String brand, String model) {
    final nb = _norm(brand);
    final nm = _norm(model);
    final haystack = '$nb $nm'.trim();

    ManualModelEntry? best;
    var bestScore = -1;

    for (final entry in kCuratedModels) {
      final eb = _norm(entry.brand);
      final em = _norm(entry.model);
      final brandOk = nb.isEmpty ||
          eb == nb ||
          nb.contains(eb) ||
          eb.contains(nb);

      var score = -1;
      if (brandOk && (em == nm || nm == em)) {
        score = 100;
      } else if (brandOk &&
          nm.isNotEmpty &&
          (nm.contains(em) || em.contains(nm))) {
        score = 80;
      }

      for (final alias in entry.aliases) {
        final a = _norm(alias);
        if (a.isEmpty) continue;
        final aliasHit = nm == a ||
            haystack == a ||
            (nm.length >= 4 && (nm.contains(a) || a.contains(nm))) ||
            haystack.contains(a);
        if (!aliasHit) continue;
        final aliasScore = brandOk ? 90 : 60;
        if (aliasScore > score) score = aliasScore;
      }

      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    return bestScore >= 60 ? best : null;
  }

  ManualBrandEntry? _findBrand(String brand) {
    final nb = _norm(brand);
    if (nb.isEmpty) return null;
    for (final b in kBrandEntries) {
      final eb = _norm(b.brand);
      if (nb == eb || nb.contains(eb) || eb.contains(nb)) return b;
    }
    return null;
  }

  ManualClassEntry _resolveClass(int? cc, String model) {
    final nm = _norm(model);
    final looksScooter = nm.contains('biz') ||
        nm.contains('pcx') ||
        nm.contains('nmax') ||
        nm.contains('scooter') ||
        nm.contains('adv') ||
        nm.contains('forza') ||
        nm.contains('sh ') ||
        nm.startsWith('sh');
    final looksTrail = nm.contains('bros') ||
        nm.contains('nxr') ||
        nm.contains('lander') ||
        nm.contains('xtz') ||
        nm.contains('xre') ||
        nm.contains('tenere') ||
        nm.contains('trail');

    if (looksScooter) {
      return kClassEntries.firstWhere((c) => c.id == 'scooter');
    }
    if (looksTrail) {
      return kClassEntries.firstWhere((c) => c.id == 'trail');
    }
    if (cc != null) {
      if (cc >= 250) {
        return kClassEntries.firstWhere((c) => c.id == 'naked_250_plus');
      }
      if (cc >= 100 && cc <= 190) {
        return kClassEntries.firstWhere((c) => c.id == 'street_100_160');
      }
    }
    return kClassEntries.firstWhere((c) => c.id == 'generic');
  }

  int? _parseCc(String displacement) {
    final match = RegExp(r'(\d{2,4})').firstMatch(displacement);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  int? _guessCcFromModel(String model) {
    final match = RegExp(r'(\d{2,4})').firstMatch(model);
    if (match == null) return null;
    final n = int.tryParse(match.group(1)!);
    if (n == null) return null;
    // evita pegar anos tipo 2020
    if (n >= 50 && n <= 1300) return n;
    return null;
  }

  List<ManualOfficialLink> _genericBrandLinks(String brand) {
    final b = brand.trim();
    if (b.isEmpty) {
      return const [
        ManualOfficialLink(
          title: 'Busque o manual oficial',
          url: 'https://www.google.com/search?q=manual+do+propriet%C3%A1rio+moto',
          note:
              'Pesquise “manual do proprietário” + marca + modelo no site oficial da fabricante.',
        ),
      ];
    }
    final q = Uri.encodeComponent('manual do proprietário $b motos brasil');
    return [
      ManualOfficialLink(
        title: 'Buscar manual oficial ($b)',
        url: 'https://www.google.com/search?q=$q',
        note: 'Abra o site oficial da marca e baixe o manual do seu modelo/ano.',
      ),
    ];
  }

  static String _norm(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
