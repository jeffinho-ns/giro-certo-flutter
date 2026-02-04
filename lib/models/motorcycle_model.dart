class MotorcycleModel {
  final String id;
  final String brand;
  final String model;
  final String displacement;
  final String abs;
  final String? imageUrl;
  final List<String> availableColors;

  MotorcycleModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.displacement,
    required this.abs,
    this.imageUrl,
    this.availableColors = const ['red', 'black', 'white'],
  });

  // Mapear nome da marca para o arquivo de imagem
  String get brandImagePath {
    final brandMap = {
      'Honda': 'honda',
      'Yamaha': 'yamaha',
      'Shineray': 'shineray',
      'Mottu (TVS)': 'mottu',
      'TVS': 'tvs',
      'Avelloz': 'avelloz',
      'Royal Enfield': 'royal',
      'Bajaj': 'bajaj',
      'Haojue': 'baja',
      'BMW Motorrad': 'bmw',
      'Triumph': 'triumph',
      'Kawasaki': 'kawasaki',
      'Dafra': 'dafra',
      'Suzuki': 'suzuki',
      'Vmoto / Voltz / Watts': 'voltz',
      'Bull Motors': 'aurat',
      'GCX': 'gcx',
      'Harley-Davidson': 'harley',
      'Ducati': 'dicati',
      'Zontes': 'gcx',
      'KTM': 'ktm',
      'Kymco': 'kymco',
      'Piaggio / Vespa': 'piaggio',
      'Vespa': 'piaggio',
      'Piaggio': 'piaggio',
    };
    return 'assets/marca/${brandMap[brand] ?? 'honda'}.png';
  }

  // Gerar caminho da imagem baseado no modelo
  String get modelImagePath {
    // Substitui espaços por hífens e deixa em minúsculas
    // Ex: "CG 125" -> "cg-125.png"
    final modelFileName = model.toLowerCase().replaceAll(' ', '-');
    final brandFolder = brand
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();
    return 'assets/marca/$brandFolder/$modelFileName.png';
  }
}
