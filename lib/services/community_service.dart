import '../models/community.dart';

/// Serviço de comunidades (mock; preparado para API).
class CommunityService {
  static final List<Community> _communities = [
    Community(
      id: 'c_delivery_sp',
      name: 'Delivery SP Centro',
      description: 'Troca de rotas, segurança e pontos quentes no centro.',
      createdByUserId: 'system',
      createdAt: DateTime.now(),
      memberCount: 142,
      zone: 'Centro',
    ),
    Community(
      id: 'c_moto_urbano',
      name: 'Pilotos Urbanos',
      description: 'Dicas de mobilidade urbana para uso diário da moto.',
      createdByUserId: 'system',
      createdAt: DateTime.now(),
      memberCount: 88,
      zone: 'Zona Sul',
    ),
    Community(
      id: 'c_manutencao',
      name: 'Oficina & Manutenção',
      description: 'Discussões sobre revisão, peças e manutenção preventiva.',
      createdByUserId: 'system',
      createdAt: DateTime.now(),
      memberCount: 63,
      zone: 'Todas',
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
    );
    _communities.insert(0, c);
    return c;
  }
}
