import 'dart:convert';
import '../models/post.dart';
import '../models/story.dart';
import '../utils/image_url.dart';
import 'api_service.dart';

/// Serviço da rede social. Usa API quando disponível; fallback para mock.
class SocialService {
  static List<Post> _cachedPosts = [];
  static List<Story> _cachedStories = [];
  static final Set<String> _likedPostIds = {};
  static final Map<String, List<SocialComment>> _commentsByPostId = {};

  static Post _postFromApi(Map<String, dynamic> json, {String? currentUserId}) {
    final user = json['user'] as Map<String, dynamic>?;
    final likes = json['likes'] as List<dynamic>? ?? [];
    final isLiked = currentUserId != null &&
        likes.any((e) => (e as Map<String, dynamic>)['userId'] == currentUserId);
    if (isLiked) _likedPostIds.add(json['id'] as String);

    final rawImages = _parseImagesList(json);
    final resolvedImages = rawImages
        ?.map((u) => resolveImageUrl(u))
        .where((u) => u.isNotEmpty)
        .toList();

    final rawPhoto = user?['photoUrl'] as String?;
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: (user?['name'] as String?) ?? '',
      userBikeModel: '',
      userAvatarUrl: (rawPhoto != null && rawPhoto.isNotEmpty) ? resolveImageUrl(rawPhoto) : null,
      content: json['content'] as String? ?? '',
      images: resolvedImages?.isNotEmpty == true ? resolvedImages : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likes: (json['likesCount'] as int?) ?? 0,
      comments: (json['commentsCount'] as int?) ?? 0,
      isSameBike: false,
    );
  }

  /// Lista posts do feed. [userBikeModel] usado para marcar "mesma moto". [currentUserId] para estado de like na API.
  static Future<List<Post>> getPosts({
    String? userBikeModel,
    String? currentUserId,
  }) async {
    try {
      final list = await ApiService.getPosts(limit: 50, offset: 0);
      _likedPostIds.clear();
      _cachedPosts = list.map((j) => _postFromApi(j, currentUserId: currentUserId)).toList();
      return List.from(_cachedPosts);
    } catch (_) {
      _cachedPosts = [];
      return [];
    }
  }

  /// Stories expiram após 24 horas.
  static const Duration storyExpiration = Duration(hours: 24);

  static bool _isStoryWithin24h(Story s) {
    return DateTime.now().difference(s.createdAt) < storyExpiration;
  }

  /// Lista stories para o carrossel (apenas das últimas 24h).
  static Future<List<Story>> getStories() async {
    try {
      final list = await ApiService.getStories();
      _cachedStories = list
          .map(_storyFromMap)
          .where(_isStoryWithin24h)
          .toList();
      return List.from(_cachedStories);
    } catch (_) {
      _cachedStories = [];
      return [];
    }
  }

  static List<String>? _parseImagesList(Map<String, dynamic> json) {
    final v = json['images'] ?? json['Images'];
    if (v == null) return null;
    List<dynamic>? list;
    if (v is List) {
      list = v;
    } else if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      try {
        final decoded = jsonDecode(s) as dynamic;
        list = decoded is List ? decoded : null;
      } catch (_) {
        list = null;
      }
      if (list == null) {
        final pgArray = _parsePostgresArray(s);
        if (pgArray != null && pgArray.isNotEmpty) return pgArray;
        return null;
      }
    } else {
      return null;
    }
    final out = <String>[];
    for (final e in list) {
      final s = e is String ? e : e?.toString();
      if (s != null && s.isNotEmpty) out.add(s);
    }
    return out.isEmpty ? null : out;
  }

  static List<String>? _parsePostgresArray(String s) {
    if (s.length < 2 || !s.startsWith('{') || !s.endsWith('}')) return null;
    final inner = s.substring(1, s.length - 1);
    if (inner.isEmpty) return [];
    final parts = inner.split(',').map((e) => e.trim().replaceAll(RegExp(r'^"|"$'), '')).where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts;
  }

  static Story _storyFromMap(Map<String, dynamic> j) {
    final rawAvatar = j['userAvatarUrl'] as String?;
    final rawMedia = (j['mediaUrl'] ?? j['media_url'])?.toString() ?? '';
    final caption = j['caption'] as String?;
    return Story(
        id: j['id'] as String,
        userId: j['userId'] as String,
        userName: (j['userName'] as String?) ?? '',
        userAvatarUrl: (rawAvatar != null && rawAvatar.isNotEmpty) ? resolveImageUrl(rawAvatar) : null,
        mediaUrl: rawMedia.isNotEmpty ? resolveImageUrl(rawMedia) : rawMedia,
        createdAt: j['createdAt'] != null ? DateTime.parse(j['createdAt'] as String) : DateTime.now(),
        likeCount: (j['likeCount'] as int?) ?? 0,
        caption: (caption != null && caption.isNotEmpty) ? caption : null,
      );
  }

  /// Lista posts de um utilizador específico.
  static Future<List<Post>> fetchPostsByUserId(
    String userId, {
    String? currentUserId,
  }) async {
    try {
      final list = await ApiService.getPosts(limit: 100, offset: 0, userId: userId);
      final posts = list.map((j) => _postFromApi(j, currentUserId: currentUserId)).toList();
      return posts.where((p) => p.userId == userId).toList();
    } catch (_) {
      return [];
    }
  }

  /// Lista stories de um utilizador específico (apenas das últimas 24h).
  static Future<List<Story>> fetchStoriesByUserId(String userId) async {
    try {
      final list = await ApiService.getStories(userId: userId);
      return list.map(_storyFromMap).where(_isStoryWithin24h).toList();
    } catch (_) {
      return [];
    }
  }

  /// Seguir utilizador. Retorna true se passou a seguir, false se já seguia ou erro.
  static Future<bool> followUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return false;
    try {
      final ok = await ApiService.followUser(targetUserId);
      if (ok) _followingIds.add(targetUserId);
      return ok;
    } catch (_) {
      _followingIds.add(targetUserId);
      return true;
    }
  }

  /// Deixar de seguir utilizador.
  static Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return false;
    try {
      final ok = await ApiService.unfollowUser(targetUserId);
      if (ok) _followingIds.remove(targetUserId);
      return ok;
    } catch (_) {
      _followingIds.remove(targetUserId);
      return true;
    }
  }

  /// Cache local de quem o utilizador atual segue (fallback quando API não retorna).
  static final Set<String> _followingIds = {};

  /// Verifica se [currentUserId] segue [targetUserId].
  static Future<bool> checkFollowStatus(
    String currentUserId,
    String targetUserId,
  ) async {
    if (currentUserId == targetUserId) return false;
    if (_followingIds.contains(targetUserId)) return true;
    try {
      final ids = await ApiService.getFollowingIds();
      _followingIds.addAll(ids);
      return ids.contains(targetUserId);
    } catch (_) {
      return false;
    }
  }

  /// Lista IDs dos utilizadores que o utilizador logado segue.
  static Future<List<String>> getFollowingIds() async {
    try {
      final ids = await ApiService.getFollowingIds();
      _followingIds.addAll(ids);
      return ids;
    } catch (_) {
      return _followingIds.toList();
    }
  }

  /// Verifica se o post está curtido (estado local).
  static bool isPostLiked(String postId) => _likedPostIds.contains(postId);

  /// Alterna like no post e retorna nova contagem. [currentLikeCount] usado quando vem da API.
  static Future<int> togglePostLike(String postId, {int? currentLikeCount}) async {
    Post? post;
    for (final p in _cachedPosts) {
      if (p.id == postId) {
        post = p;
        break;
      }
    }
    final count = currentLikeCount ?? post?.likes ?? 0;

    try {
      final liked = await ApiService.togglePostLike(postId);
      if (liked) {
        _likedPostIds.add(postId);
        return count + 1;
      } else {
        _likedPostIds.remove(postId);
        return count - 1;
      }
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (post == null) return 0;
      if (_likedPostIds.contains(postId)) {
        _likedPostIds.remove(postId);
        return post.likes - 1;
      } else {
        _likedPostIds.add(postId);
        return post.likes + 1;
      }
    }
  }

  /// Retorna contagem atual de likes do post (considerando estado local).
  static int getPostLikeCount(Post post) {
    if (_likedPostIds.contains(post.id)) return post.likes + 1;
    return post.likes;
  }

  /// Comentários de um post.
  static Future<List<SocialComment>> getComments(String postId) async {
    try {
      final list = await ApiService.getPostComments(postId);
      final comments = list.map((c) {
        final u = c['user'] as Map<String, dynamic>?;
        return SocialComment(
          id: c['id'] as String,
          userId: u?['id'] as String? ?? '',
          userName: u?['name'] as String? ?? '',
          text: c['content'] as String? ?? '',
          createdAt: c['createdAt'] != null
              ? DateTime.parse(c['createdAt'] as String)
              : DateTime.now(),
        );
      }).toList();
      return comments;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 150));
      return List.from(_commentsByPostId[postId] ?? []);
    }
  }

  /// Adiciona comentário.
  static Future<List<SocialComment>> addComment(
    String postId, {
    required String userId,
    required String userName,
    required String text,
  }) async {
    try {
      await ApiService.addPostComment(postId, content: text);
      return getComments(postId);
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 150));
      final list = _commentsByPostId.putIfAbsent(postId, () => []);
      final comment = SocialComment(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        text: text,
        createdAt: DateTime.now(),
      );
      list.add(comment);
      return List.from(list);
    }
  }

  /// Cria novo post. Se [imageUrls] contiver caminhos locais, faz upload primeiro.
  /// O post só é criado quando todas as imagens forem enviadas com sucesso (igual às stories).
  static Future<Post> createPost({
    required String userId,
    required String userName,
    required String userBikeModel,
    String? userAvatarUrl,
    required String content,
    List<String>? imageUrls,
  }) async {
    List<String>? urlsToSend = imageUrls;
    if (imageUrls != null && imageUrls.isNotEmpty) {
      final uploadedUrls = <String>[];
      for (final path in imageUrls) {
        if (path.startsWith('http')) {
          uploadedUrls.add(path);
        } else {
          final url = await ApiService.uploadPostImage(path, userId);
          uploadedUrls.add(url);
        }
      }
      urlsToSend = uploadedUrls;
    }
    try {
      final raw = await ApiService.createPost(
        content: content,
        images: urlsToSend,
      );
      final post = _postFromApi(raw, currentUserId: userId);
      _cachedPosts.insert(0, post);
      return post;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 400));
      final post = Post(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        userBikeModel: userBikeModel,
        userAvatarUrl: userAvatarUrl,
        content: content,
        images: urlsToSend,
        createdAt: DateTime.now(),
        likes: 0,
        comments: 0,
        isSameBike: false,
      );
      _cachedPosts.insert(0, post);
      return post;
    }
  }

  /// Elimina story na API e do cache local. Só o dono pode excluir.
  static Future<void> deleteStory(String storyId) async {
    await ApiService.deleteStory(storyId);
    _cachedStories = _cachedStories.where((s) => s.id != storyId).toList();
  }

  /// Cria novo story. Se mediaUrl for caminho local, faz upload primeiro.
  /// Só retorna quando o upload e a criação na API estiverem concluídos.
  /// Se o upload falhar, lança exceção para não guardar URL inválida.
  static Future<Story> createStory({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String mediaUrl,
    String? caption,
  }) async {
    String finalUrl = mediaUrl;
    if (!mediaUrl.startsWith('http')) {
      finalUrl = await ApiService.uploadStoryImage(mediaUrl, userId);
    }
    try {
      final j = await ApiService.createStory(finalUrl, caption: caption);
      final story = _storyFromMap(j);
      _cachedStories.insert(0, story);
      return story;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 300));
      final story = Story(
        id: 's_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        mediaUrl: finalUrl,
        createdAt: DateTime.now(),
        likeCount: 0,
        caption: caption,
      );
      _cachedStories.insert(0, story);
      return story;
    }
  }

  /// Filtra posts por texto (busca local).
  static List<Post> filterPosts(List<Post> posts, String query) {
    if (query.trim().isEmpty) return posts;
    final q = query.trim().toLowerCase();
    return posts.where((p) {
      return p.content.toLowerCase().contains(q) ||
          p.userName.toLowerCase().contains(q) ||
          p.userBikeModel.toLowerCase().contains(q);
    }).toList();
  }

  /// Ordenação do feed.
  static List<Post> sortPosts(List<Post> posts, FeedOrder order) {
    final list = List<Post>.from(posts);
    switch (order) {
      case FeedOrder.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FeedOrder.popular:
        list.sort((a, b) => (b.likes + b.comments).compareTo(a.likes + a.comments));
        break;
    }
    return list;
  }

  /// Posts com paginação (mock: ignora offset e retorna todos).
  static Future<List<Post>> getPostsPaginated({
    String? userBikeModel,
    int limit = 20,
    int offset = 0,
    FeedOrder order = FeedOrder.recent,
  }) async {
    final posts = await getPosts(userBikeModel: userBikeModel);
    final sorted = sortPosts(posts, order);
    if (offset >= sorted.length) return [];
    final end = (offset + limit).clamp(0, sorted.length);
    return sorted.sublist(offset, end);
  }

  /// Guardar/desmarcar post (mock).
  static final Set<String> _savedPostIds = {};

  static bool isPostSaved(String postId) => _savedPostIds.contains(postId);

  static Future<bool> toggleSavePost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_savedPostIds.contains(postId)) {
      _savedPostIds.remove(postId);
      return false;
    }
    _savedPostIds.add(postId);
    return true;
  }

  /// Excluir post.
  static Future<bool> deletePost(String postId, String userId) async {
    try {
      await ApiService.deletePost(postId);
      final i = _cachedPosts.indexWhere((p) => p.id == postId && p.userId == userId);
      if (i >= 0) _cachedPosts.removeAt(i);
      return true;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 200));
      final i = _cachedPosts.indexWhere((p) => p.id == postId && p.userId == userId);
      if (i >= 0) {
        _cachedPosts.removeAt(i);
        return true;
      }
      return false;
    }
  }

  /// Atualizar post (mock).
  static Future<Post?> updatePost(
    String postId,
    String userId, {
    required String content,
    List<String>? imageUrls,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _cachedPosts.indexWhere((p) => p.id == postId && p.userId == userId);
    if (i < 0) return null;
    final old = _cachedPosts[i];
    final updated = old.copyWith(content: content, images: imageUrls ?? old.images);
    _cachedPosts[i] = updated;
    return updated;
  }

  /// Reportar post.
  static Future<void> reportPost(String postId, String reason) async {
    try {
      await ApiService.reportPost(postId, reason);
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }
}

enum FeedOrder { recent, popular }

class SocialComment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  const SocialComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });
}
