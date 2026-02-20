import '../models/post.dart';
import '../models/story.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

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

    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: (user?['name'] as String?) ?? '',
      userBikeModel: '',
      userAvatarUrl: user?['photoUrl'] as String?,
      content: json['content'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
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
      await Future.delayed(const Duration(milliseconds: 300));
      _cachedPosts = MockDataService.getMockPosts(userBikeModel ?? '');
      return List.from(_cachedPosts);
    }
  }

  /// Lista stories para o carrossel.
  static Future<List<Story>> getStories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _cachedStories = MockDataService.getMockStories();
    return List.from(_cachedStories);
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

  /// Cria novo post.
  static Future<Post> createPost({
    required String userId,
    required String userName,
    required String userBikeModel,
    String? userAvatarUrl,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final raw = await ApiService.createPost(
        content: content,
        images: imageUrls,
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
        images: imageUrls,
        createdAt: DateTime.now(),
        likes: 0,
        comments: 0,
        isSameBike: false,
      );
      _cachedPosts.insert(0, post);
      return post;
    }
  }

  /// Cria novo story (mock).
  static Future<Story> createStory({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String mediaUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final story = Story(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
      likeCount: 0,
    );
    _cachedStories.insert(0, story);
    return story;
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

  /// Reportar post (mock: só registra).
  static Future<void> reportPost(String postId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Em produção enviaria para API
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
