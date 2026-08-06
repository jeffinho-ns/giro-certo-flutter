// Modelos de conteúdo do Guia do piloto (Manual).
// Conteúdo curado / genérico — não substitui o manual do fabricante.

class ManualGuideItem {
  final String key;
  final String title;
  final String description;
  final String tips;

  const ManualGuideItem({
    required this.key,
    required this.title,
    required this.description,
    required this.tips,
  });
}

class ManualPartItem {
  final String key;
  final String title;
  final String description;
  final String icon;

  const ManualPartItem({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class ManualOfficialLink {
  final String title;
  final String url;
  final String? note;

  const ManualOfficialLink({
    required this.title,
    required this.url,
    this.note,
  });
}

class ManualMaintenanceSchedule {
  final String oilInterval;
  final String chainCare;
  final String tireCheck;
  final String brakeCheck;
  final String otherNotes;
  final bool isApproximate;

  const ManualMaintenanceSchedule({
    required this.oilInterval,
    required this.chainCare,
    required this.tireCheck,
    required this.brakeCheck,
    this.otherNotes = '',
    this.isApproximate = true,
  });
}

enum ManualContentMatchLevel {
  exactModel,
  brand,
  displacementClass,
  generic,
  none,
}

class ManualBikeContent {
  final String? bikeLabel;
  final String? brand;
  final String? model;
  final int? displacementCc;
  final String? vehicleClass;
  final ManualContentMatchLevel matchLevel;
  final ManualMaintenanceSchedule schedule;
  final List<String> modelTips;
  final List<ManualOfficialLink> officialLinks;
  final bool hasBike;

  const ManualBikeContent({
    required this.bikeLabel,
    required this.brand,
    required this.model,
    required this.displacementCc,
    required this.vehicleClass,
    required this.matchLevel,
    required this.schedule,
    required this.modelTips,
    required this.officialLinks,
    required this.hasBike,
  });

  factory ManualBikeContent.empty() {
    return const ManualBikeContent(
      bikeLabel: null,
      brand: null,
      model: null,
      displacementCc: null,
      vehicleClass: null,
      matchLevel: ManualContentMatchLevel.none,
      schedule: ManualContentCatalogDefaults.genericStreetSchedule,
      modelTips: <String>[],
      officialLinks: <ManualOfficialLink>[],
      hasBike: false,
    );
  }
}

class ManualBundle {
  final ManualBikeContent bikeContent;
  final List<ManualGuideItem> beginnerGuides;
  final List<ManualPartItem> parts;

  const ManualBundle({
    required this.bikeContent,
    required this.beginnerGuides,
    required this.parts,
  });
}

/// Defaults compartilhados (evita ciclo de imports com o catálogo).
class ManualContentCatalogDefaults {
  static const genericStreetSchedule = ManualMaintenanceSchedule(
    oilInterval: 'A cada ~3.000–5.000 km ou 6 meses (o que vier primeiro)',
    chainCare: 'Lubrificar a cada ~500–800 km; ajustar folga conforme manual',
    tireCheck: 'Pressão semanal; sulco mínimo ~1,6 mm',
    brakeCheck: 'Pastilhas e fluido: inspecionar a cada ~5.000 km',
    otherNotes:
        'Intervalos aproximados do mercado BR. Confirme sempre no manual do fabricante.',
  );
}
