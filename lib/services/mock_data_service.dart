import '../models/user.dart';
import '../models/bike.dart';
import '../models/part.dart';
import '../models/post.dart';
import '../models/delivery_order.dart';
import '../models/story.dart';

class MockDataService {
  static User? _cachedUser;
  static Bike? _cachedBike;

  static User getMockUser({bool isPartner = false}) {
    if (_cachedUser != null && _cachedUser!.isPartner == isPartner) {
      return _cachedUser!;
    }
    
    _cachedUser = User(
      id: '1',
      name: isPartner ? 'Loja MotoPeças' : 'João Silva',
      email: isPartner ? 'loja@example.com' : 'joao@example.com',
      age: isPartner ? 0 : 28,
      pilotProfile: isPartner ? 'Diario' : 'Diario',
      role: UserRole.user,
      partnerId: isPartner ? 'p1' : null,
      isSubscriber: false,
      hasVerifiedDocuments: !isPartner,
      verificationBadge: false,
      isOnline: true,
    );
    return _cachedUser!;
  }

  static Bike getMockBike() {
    _cachedBike = Bike(
      id: '1',
      model: 'CB 650F',
      brand: 'Honda',
      plate: 'ABC-1234',
      currentKm: 12450,
      oilType: '10W-40 Sintético',
      frontTirePressure: 2.5,
      rearTirePressure: 2.8,
      photoUrl: 'assets/images/moto-black.png',
      vehiclePhotoUrl: null,
      nickname: 'Fera do Asfalto',
      ridingStyle: 'Urbano',
      accessories: const ['Suporte celular', 'Bau', 'Iluminacao LED'],
      nextUpgrade: 'Escapamento esportivo',
      preferredColor: 'Vermelho',
      additionalPhotos: const ['assets/images/moto-black.png'],
    );
    return _cachedBike!;
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

  static List<Story> getMockStories() {
    return [
      Story(
        id: 'st1',
        userId: '2',
        userName: 'Maria Santos',
        userAvatarUrl: null,
        mediaUrl: 'assets/images/prev-story-1.png',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likeCount: 12,
      ),
      Story(
        id: 'st2',
        userId: '3',
        userName: 'Pedro Costa',
        userAvatarUrl: null,
        mediaUrl: 'assets/images/prev-story-2.png',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likeCount: 8,
      ),
      Story(
        id: 'st3',
        userId: '4',
        userName: 'Ana Oliveira',
        userAvatarUrl: null,
        mediaUrl: 'assets/images/prev-story-3.png',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        likeCount: 15,
      ),
      Story(
        id: 'st4',
        userId: '5',
        userName: 'Carlos Mendes',
        userAvatarUrl: null,
        mediaUrl: 'assets/images/prev-story-1.png',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        likeCount: 6,
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

  static List<DeliveryOrder> getMockDeliveryOrders(double userLat, double userLng) {
    final now = DateTime.now();
    return [
      DeliveryOrder(
        id: 'd1',
        storeId: 'p1',
        storeName: 'MotoPeças Central',
        storeAddress: 'Av. Paulista, 1000 - São Paulo, SP',
        storeLatitude: -23.5505,
        storeLongitude: -46.6333,
        deliveryAddress: 'Rua Augusta, 200 - Consolação, São Paulo, SP',
        deliveryLatitude: -23.5475,
        deliveryLongitude: -46.6512,
        recipientName: 'Carlos Silva',
        recipientPhone: '(11) 98765-4321',
        notes: 'Entregar no portão principal. Apartamento 101.',
        value: 150.00,
        deliveryFee: 12.50,
        status: DeliveryStatus.pending,
        priority: DeliveryPriority.normal,
        createdAt: now.subtract(const Duration(minutes: 15)),
        distance: 2.3,
        estimatedTime: 15,
      ),
      DeliveryOrder(
        id: 'd2',
        storeId: 'p2',
        storeName: 'Bike Shop Premium',
        storeAddress: 'Rua Augusta, 500 - São Paulo, SP',
        storeLatitude: -23.5475,
        storeLongitude: -46.6512,
        deliveryAddress: 'Av. Consolação, 1500 - Bela Vista, São Paulo, SP',
        deliveryLatitude: -23.5489,
        deliveryLongitude: -46.6564,
        recipientName: 'Ana Costa',
        recipientPhone: '(11) 99876-5432',
        notes: 'Urgente! Cliente aguardando.',
        value: 320.00,
        deliveryFee: 18.00,
        status: DeliveryStatus.pending,
        priority: DeliveryPriority.urgent,
        createdAt: now.subtract(const Duration(minutes: 5)),
        distance: 1.8,
        estimatedTime: 12,
      ),
      DeliveryOrder(
        id: 'd3',
        storeId: 'p1',
        storeName: 'MotoPeças Central',
        storeAddress: 'Av. Paulista, 1000 - São Paulo, SP',
        storeLatitude: -23.5505,
        storeLongitude: -46.6333,
        deliveryAddress: 'Rua dos Três Irmãos, 50 - Butantã, São Paulo, SP',
        deliveryLatitude: -23.5615,
        deliveryLongitude: -46.7282,
        recipientName: 'Pedro Santos',
        recipientPhone: '(11) 97654-3210',
        notes: null,
        value: 85.00,
        deliveryFee: 15.00,
        status: DeliveryStatus.pending,
        priority: DeliveryPriority.low,
        createdAt: now.subtract(const Duration(minutes: 30)),
        distance: 8.5,
        estimatedTime: 25,
      ),
      DeliveryOrder(
        id: 'd4',
        storeId: 'p7',
        storeName: 'Loja de Pneus Rápido',
        storeAddress: 'Av. Faria Lima, 800 - São Paulo, SP',
        storeLatitude: -23.5676,
        storeLongitude: -46.6928,
        deliveryAddress: 'Av. Rebouças, 1200 - Pinheiros, São Paulo, SP',
        deliveryLatitude: -23.5672,
        deliveryLongitude: -46.6744,
        recipientName: 'Maria Oliveira',
        recipientPhone: '(11) 96543-2109',
        notes: 'Entregar na recepção do prédio.',
        value: 450.00,
        deliveryFee: 20.00,
        status: DeliveryStatus.pending,
        priority: DeliveryPriority.high,
        createdAt: now.subtract(const Duration(minutes: 10)),
        distance: 2.1,
        estimatedTime: 10,
      ),
      DeliveryOrder(
        id: 'd5',
        storeId: 'p3',
        storeName: 'AutoMoto Express',
        storeAddress: 'Av. Consolação, 2000 - São Paulo, SP',
        storeLatitude: -23.5489,
        storeLongitude: -46.6564,
        deliveryAddress: 'Rua Harmonia, 150 - Vila Madalena, São Paulo, SP',
        deliveryLatitude: -23.5431,
        deliveryLongitude: -46.6913,
        recipientName: 'João Mendes',
        recipientPhone: '(11) 95432-1098',
        notes: null,
        value: 120.00,
        deliveryFee: 10.00,
        status: DeliveryStatus.accepted,
        priority: DeliveryPriority.normal,
        createdAt: now.subtract(const Duration(hours: 1)),
        acceptedAt: now.subtract(const Duration(minutes: 45)),
        riderId: 'r1',
        riderName: 'Roberto Alves',
        distance: 3.2,
        estimatedTime: 18,
      ),
      DeliveryOrder(
        id: 'd6',
        storeId: 'p2',
        storeName: 'Bike Shop Premium',
        storeAddress: 'Rua Augusta, 500 - São Paulo, SP',
        storeLatitude: -23.5475,
        storeLongitude: -46.6512,
        deliveryAddress: 'Av. Paulista, 2000 - Bela Vista, São Paulo, SP',
        deliveryLatitude: -23.5515,
        deliveryLongitude: -46.6533,
        recipientName: 'Fernanda Lima',
        recipientPhone: '(11) 94321-0987',
        notes: 'Cliente preferencial. Entregar com cuidado.',
        value: 280.00,
        deliveryFee: 14.00,
        status: DeliveryStatus.inProgress,
        priority: DeliveryPriority.high,
        createdAt: now.subtract(const Duration(hours: 2)),
        acceptedAt: now.subtract(const Duration(minutes: 30)),
        riderId: 'r2',
        riderName: 'Lucas Pereira',
        distance: 1.5,
        estimatedTime: 8,
      ),
    ];
  }

  // Retorna áreas com mais pedidos (para mapa de calor)
  static List<Map<String, dynamic>> getHotDeliveryZones() {
    return [
      {
        'latitude': -23.5505,
        'longitude': -46.6333,
        'orderCount': 8,
        'zoneName': 'Centro',
      },
      {
        'latitude': -23.5475,
        'longitude': -46.6512,
        'orderCount': 5,
        'zoneName': 'Consolação',
      },
      {
        'latitude': -23.5676,
        'longitude': -46.6928,
        'orderCount': 6,
        'zoneName': 'Faria Lima',
      },
      {
        'latitude': -23.5431,
        'longitude': -46.6913,
        'orderCount': 4,
        'zoneName': 'Vila Madalena',
      },
    ];
  }
}
