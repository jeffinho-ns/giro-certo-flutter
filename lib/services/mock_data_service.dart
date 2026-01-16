import '../models/user.dart';
import '../models/bike.dart';
import '../models/maintenance.dart';
import '../models/part.dart';
import '../models/post.dart';
import '../models/partner.dart';

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

  static List<Partner> getMockPartners() {
    return [
      // Lojas
      Partner(
        id: 'p1',
        name: 'MotoPeças Central',
        type: PartnerType.store,
        address: 'Av. Paulista, 1000 - São Paulo, SP',
        latitude: -23.5505,
        longitude: -46.6333,
        rating: 4.7,
        isTrusted: true,
        specialties: ['Óleo', 'Pneus', 'Filtros'],
        activePromotions: [
          Promotion(
            id: 'promo1',
            description: '10% de desconto em óleo Motul',
            code: 'GIRO10',
            discountPercentage: 10.0,
            category: 'Óleo',
          ),
          Promotion(
            id: 'promo2',
            description: '15% de desconto em filtros de ar',
            code: 'FILTRO15',
            discountPercentage: 15.0,
            category: 'Filtros',
          ),
        ],
      ),
      Partner(
        id: 'p2',
        name: 'Bike Shop Premium',
        type: PartnerType.store,
        address: 'Rua Augusta, 500 - São Paulo, SP',
        latitude: -23.5475,
        longitude: -46.6512,
        rating: 4.9,
        isTrusted: true,
        specialties: ['Pneus', 'Travões', 'Acessórios'],
        activePromotions: [
          Promotion(
            id: 'promo3',
            description: '20% de desconto em pneus Michelin',
            code: 'PNEU20',
            discountPercentage: 20.0,
            category: 'Pneus',
          ),
        ],
      ),
      Partner(
        id: 'p3',
        name: 'AutoMoto Express',
        type: PartnerType.store,
        address: 'Av. Consolação, 2000 - São Paulo, SP',
        latitude: -23.5489,
        longitude: -46.6564,
        rating: 4.5,
        isTrusted: false,
        specialties: ['Óleo', 'Travões'],
        activePromotions: [
          Promotion(
            id: 'promo4',
            description: '5% de desconto em qualquer produto',
            code: 'EXPRESS5',
            discountPercentage: 5.0,
          ),
        ],
      ),
      // Mecânicos de Confiança
      Partner(
        id: 'p4',
        name: 'Mecânica Speed Motors',
        type: PartnerType.mechanic,
        address: 'Rua dos Três Irmãos, 100 - São Paulo, SP',
        latitude: -23.5615,
        longitude: -46.7282,
        rating: 4.8,
        isTrusted: true,
        specialties: ['Manutenção Completa', 'Travões', 'Motor'],
        activePromotions: [
          Promotion(
            id: 'promo5',
            description: 'Revisão completa com 12% de desconto',
            code: 'SPEED12',
            discountPercentage: 12.0,
          ),
        ],
      ),
      Partner(
        id: 'p5',
        name: 'Oficina MotoExpert',
        type: PartnerType.mechanic,
        address: 'Av. Rebouças, 1500 - São Paulo, SP',
        latitude: -23.5672,
        longitude: -46.6744,
        rating: 4.6,
        isTrusted: true,
        specialties: ['Pneus', 'Transmissão', 'Suspensão'],
        activePromotions: [
          Promotion(
            id: 'promo6',
            description: 'Troca de pneus com instalação grátis',
            code: 'EXPERTGRATIS',
            discountPercentage: 0.0,
            category: 'Pneus',
          ),
        ],
      ),
      Partner(
        id: 'p6',
        name: 'Moto Service Vila Madalena',
        type: PartnerType.mechanic,
        address: 'Rua Harmonia, 300 - São Paulo, SP',
        latitude: -23.5431,
        longitude: -46.6913,
        rating: 4.4,
        isTrusted: false,
        specialties: ['Óleo', 'Filtros'],
        activePromotions: [],
      ),
      Partner(
        id: 'p7',
        name: 'Loja de Pneus Rápido',
        type: PartnerType.store,
        address: 'Av. Faria Lima, 800 - São Paulo, SP',
        latitude: -23.5676,
        longitude: -46.6928,
        rating: 4.3,
        isTrusted: false,
        specialties: ['Pneus'],
        activePromotions: [
          Promotion(
            id: 'promo7',
            description: 'Pneus com menor preço garantido',
            code: 'MENORPRECO',
            discountPercentage: 8.0,
            category: 'Pneus',
          ),
        ],
      ),
    ];
  }
}
