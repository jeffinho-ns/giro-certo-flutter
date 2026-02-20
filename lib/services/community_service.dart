import '../models/community.dart';

/// Serviço de comunidades (mock; preparado para API).
class CommunityService {
  static final List<Community> _communities = [];

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
