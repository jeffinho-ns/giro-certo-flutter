import '../models/community.dart';
import '../models/community_type.dart';

/// Serviço de comunidades (seed local tipado; preparado para API).
class CommunityService {
  static final List<Community> _communities = [
    Community(
      id: 'c_delivery_sp',
      name: 'Delivery SP Centro',
      description:
          'Troca de rotas, segurança e pontos quentes para quem trabalha com entregas no centro.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 6, 12),
      memberCount: 142,
      type: CommunityType.delivery,
      zone: 'Centro',
    ),
    Community(
      id: 'c_delivery_zona_leste',
      name: 'Entregadores Zona Leste',
      description:
          'Grupo de quem vive de app: dicas de corrida, horários e apoio na região leste.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 8, 3),
      memberCount: 97,
      type: CommunityType.delivery,
      zone: 'Zona Leste',
    ),
    Community(
      id: 'c_moto_urbano',
      name: 'Motos Urbanos',
      description: 'Dicas de mobilidade urbana para uso diário da moto no trânsito.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 5, 20),
      memberCount: 88,
      type: CommunityType.zona,
      zone: 'Zona Sul',
    ),
    Community(
      id: 'c_zona_norte',
      name: 'Pilotos Zona Norte',
      description: 'Encontros, avisos de blitz e rotas da zona norte.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 7, 1),
      memberCount: 54,
      type: CommunityType.zona,
      zone: 'Zona Norte',
    ),
    Community(
      id: 'c_manutencao',
      name: 'Oficina & Manutenção',
      description: 'Discussões sobre revisão, peças e manutenção preventiva.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 4, 15),
      memberCount: 63,
      type: CommunityType.manutencao,
      zone: 'Todas',
    ),
    Community(
      id: 'c_lazer_fds',
      name: 'Rolê de Fim de Semana',
      description: 'Passeios leves, pontos de encontro e fotos da tropa.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 9, 10),
      memberCount: 120,
      type: CommunityType.lazer,
      zone: 'Grande SP',
    ),
    Community(
      id: 'c_marca_honda',
      name: 'Honda Brasil',
      description: 'CG, Bros, Biz e Twister: dicas, setup e encontros da marca.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 3, 8),
      memberCount: 210,
      type: CommunityType.marca,
      zone: 'Nacional',
    ),
    Community(
      id: 'c_marca_yamaha',
      name: 'Yamaha Brasil',
      description: 'Factor, Fazer, Lander e NMAX — comunidade da marca.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 3, 22),
      memberCount: 156,
      type: CommunityType.marca,
      zone: 'Nacional',
    ),
    Community(
      id: 'c_geral',
      name: 'Giro Certo — Geral',
      description: 'Comunidade aberta a todos os pilotos do app.',
      createdByUserId: 'system',
      createdAt: DateTime(2025, 1, 5),
      memberCount: 480,
      type: CommunityType.geral,
      zone: 'Brasil',
    ),
  ];

  /// Lista comunidades do utilizador / disponíveis.
  static Future<List<Community>> getCommunities({String? userId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_communities);
  }

  /// Cria nova comunidade.
  static Future<Community> createCommunity({
    required String name,
    required String description,
    String? imageUrl,
    required String createdByUserId,
    CommunityType type = CommunityType.geral,
    String? zone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final c = Community(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      imageUrl: imageUrl,
      createdByUserId: createdByUserId,
      createdAt: DateTime.now(),
      memberCount: 1,
      type: type,
      zone: zone,
    );
    _communities.insert(0, c);
    return c;
  }
}
