import '../models/user.dart';
import '../models/bike.dart';
import '../models/maintenance.dart';
import '../models/part.dart';
import '../models/post.dart';

class MockDataService {
  static User? _cachedUser;
  static Bike? _cachedBike;
  static List<Maintenance>? _cachedMaintenances;
  static List<Part>? _cachedParts;
  static List<Post>? _cachedPosts;

  static User getMockUser() {
    if (_cachedUser != null) return _cachedUser!;
    _cachedUser = User(
      id: '1',
      name: 'João Silva',
      email: 'joao@example.com',
      age: 28,
      pilotProfile: 'Urbano',
    );
    return _cachedUser!;
  }

  static Bike getMockBike() {
    return Bike(
      id: '1',
      model: 'CB 650F',
      brand: 'Honda',
      plate: 'ABC-1234',
      currentKm: 12450,
      oilType: '10W-40 Sintético',
      frontTirePressure: 2.5,
      rearTirePressure: 2.8,
    );
    return _cachedBike!;
  }

  static List<Maintenance> getMockMaintenances(int currentKm) {
    return [
      Maintenance(
        id: '1',
        partName: 'Óleo do Motor',
        category: 'Óleo',
        lastChangeKm: 10000,
        recommendedChangeKm: 15000,
        currentKm: currentKm,
        wearPercentage: 0.20, // 80% de saúde
        status: 'OK',
      ),
      Maintenance(
        id: '2',
        partName: 'Pneus Dianteiro e Traseiro',
        category: 'Pneus',
        lastChangeKm: 8000,
        recommendedChangeKm: 15000,
        currentKm: currentKm,
        wearPercentage: 0.55, // 45% de saúde
        status: 'Atenção',
      ),
      Maintenance(
        id: '3',
        partName: 'Pastilhas de Travão',
        category: 'Travões',
        lastChangeKm: 9000,
        recommendedChangeKm: 12000,
        currentKm: currentKm,
        wearPercentage: 0.15, // 85% de saúde
        status: 'OK',
      ),
      Maintenance(
        id: '4',
        partName: 'Filtro de Ar',
        category: 'Filtros',
        lastChangeKm: 10000,
        recommendedChangeKm: 15000,
        currentKm: currentKm,
        wearPercentage: 0.30,
        status: 'OK',
      ),
      Maintenance(
        id: '5',
        partName: 'Corrente',
        category: 'Transmissão',
        lastChangeKm: 7000,
        recommendedChangeKm: 20000,
        currentKm: currentKm,
        wearPercentage: 0.25,
        status: 'OK',
      ),
      Maintenance(
        id: '6',
        partName: 'Fluido de Travão',
        category: 'Travões',
        lastChangeKm: 5000,
        recommendedChangeKm: 15000,
        currentKm: currentKm,
        wearPercentage: 0.40,
        status: 'Atenção',
      ),
    ];
  }

  static List<Part> getMockParts() {
    return [
      Part(
        id: '1',
        name: 'Óleo Motul 7100 10W-40',
        category: 'Performance',
        brand: 'Motul',
        rating: 4.8,
        reviewCount: 342,
        description: 'Óleo sintético de alta performance para motos esportivas',
        compatibleModels: ['CB 650F', 'CB 600F', 'CBR 650F'],
      ),
      Part(
        id: '2',
        name: 'Pneus Michelin Pilot Road 5',
        category: 'Custo-Benefício',
        brand: 'Michelin',
        rating: 4.9,
        reviewCount: 521,
        description: 'Excelente aderência em piso molhado e seca',
        compatibleModels: ['CB 650F', 'CB 600F'],
      ),
      Part(
        id: '3',
        name: 'Escape Akrapovic Slip-On',
        category: 'Performance',
        brand: 'Akrapovic',
        rating: 4.7,
        reviewCount: 189,
        description: 'Aumento de potência e som esportivo',
        compatibleModels: ['CB 650F', 'CB 600F'],
      ),
      Part(
        id: '4',
        name: 'Banco Comfort Seat',
        category: 'Conforto',
        brand: 'Seat Concepts',
        rating: 4.6,
        reviewCount: 234,
        description: 'Banco mais confortável para viagens longas',
        compatibleModels: ['CB 650F'],
      ),
      Part(
        id: '5',
        name: 'Protetor de Carenagem',
        category: 'Estética',
        brand: 'Puig',
        rating: 4.5,
        reviewCount: 156,
        description: 'Proteção e estilo para sua moto',
        compatibleModels: ['CB 650F', 'CB 600F'],
      ),
    ];
  }

  static List<Post> getMockPosts(String userBikeModel) {
    return [
      Post(
        id: '1',
        userId: '2',
        userName: 'Maria Santos',
        userBikeModel: 'CB 650F',
        content: 'Acabei de trocar o óleo com Motul 7100. Excelente produto! Moto mais suave agora.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 23,
        comments: 5,
        isSameBike: true,
      ),
      Post(
        id: '2',
        userId: '3',
        userName: 'Pedro Costa',
        userBikeModel: 'Yamaha MT-07',
        content: 'Dica: Sempre verifico a pressão dos pneus antes de sair. Segurança em primeiro lugar!',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 45,
        comments: 12,
        isSameBike: false,
      ),
      Post(
        id: '3',
        userId: '4',
        userName: 'Ana Oliveira',
        userBikeModel: 'CB 650F',
        content: 'Alguém recomenda uma oficina confiável na zona norte de SP? Preciso fazer revisão.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        likes: 18,
        comments: 8,
        isSameBike: true,
      ),
      Post(
        id: '4',
        userId: '5',
        userName: 'Carlos Mendes',
        userBikeModel: 'Kawasaki Z650',
        content: 'Finalmente consegui fazer a manutenção completa. Tudo em dia! 🏍️',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        likes: 32,
        comments: 6,
        isSameBike: false,
      ),
      Post(
        id: '5',
        userId: '6',
        userName: 'Juliana Lima',
        userBikeModel: 'CB 650F',
        content: 'Troquei os pneus para Michelin Pilot Road 5. Que diferença na aderência! Recomendo demais.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        likes: 67,
        comments: 15,
        isSameBike: true,
      ),
    ];
  }
}
