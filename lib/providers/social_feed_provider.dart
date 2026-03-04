import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../models/story.dart';
import '../services/social_service.dart';
import '../services/api_service.dart';

/// Tipo de feed: Para Você (global) ou Seguindo (filtrado por amizade).
enum FeedTab { forYou, following }

/// Filtro por tipo de piloto no feed.
enum FeedPilotFilter { all, delivery, lazer }

class SocialFeedProvider extends ChangeNotifier {
  List<Post> _posts = [];
  List<Story> _stories = [];
  String _searchQuery = '';
  String _hashtagFilter = '';
  bool _loading = true;
  final Map<String, int> _likeCountOverrides = {};
  FeedOrder _feedOrder = FeedOrder.recent;
  FeedTab _feedTab = FeedTab.forYou;
  FeedPilotFilter _pilotFilter = FeedPilotFilter.all;

  /// Posts e stories por userId (perfis específicos).
  final Map<String, List<Post>> _profilePosts = {};
  final Map<String, List<Story>> _profileStories = {};
  final Map<String, Map<String, dynamic>> _profileUserData = {};
  final Map<String, bool> _profileLoading = {};
  final Map<String, bool> _isFollowing = {};

  List<Post> get posts => _posts;
  List<Story> get stories => _stories;
  String get searchQuery => _searchQuery;
  String get hashtagFilter => _hashtagFilter;
  bool get loading => _loading;
  FeedOrder get feedOrder => _feedOrder;
  FeedTab get feedTab => _feedTab;
  FeedPilotFilter get pilotFilter => _pilotFilter;

  List<Post> getProfilePosts(String userId) =>
      List.from(_profilePosts[userId] ?? []);
  List<Story> getProfileStories(String userId) =>
      List.from(_profileStories[userId] ?? []);
  Map<String, dynamic>? getProfileUserData(String userId) =>
      _profileUserData[userId];
  bool isProfileLoading(String userId) => _profileLoading[userId] ?? false;
  bool isFollowing(String userId) => _isFollowing[userId] ?? false;

  /// IDs que o utilizador logado segue (para filtrar feed "Seguindo").
  final Set<String> _followingIds = {};

  List<Post> get filteredPosts {
    var list = SocialService.filterPosts(_posts, _searchQuery);
    if (_feedTab == FeedTab.following) {
      list = list.where((p) => _followingIds.contains(p.userId)).toList();
    }
    if (_pilotFilter == FeedPilotFilter.delivery) {
      list = list.where((p) => p.isDeliveryAuthor).toList();
    } else if (_pilotFilter == FeedPilotFilter.lazer) {
      list = list.where((p) => !p.isDeliveryAuthor).toList();
    }
    if (_hashtagFilter.isNotEmpty) {
      final tag = _hashtagFilter.replaceFirst(RegExp(r'^#'), '').toLowerCase();
      list = list.where((p) => p.hashtags.any((h) => h.toLowerCase() == tag)).toList();
    }
    return SocialService.sortPosts(list, _feedOrder);
  }

  void setFeedTab(FeedTab tab) {
    if (_feedTab == tab) return;
    _feedTab = tab;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setHashtagFilter(String value) {
    if (_hashtagFilter == value) return;
    _hashtagFilter = value.replaceFirst(RegExp(r'^#'), '').trim();
    notifyListeners();
  }

  void setPilotFilter(FeedPilotFilter value) {
    if (_pilotFilter == value) return;
    _pilotFilter = value;
    notifyListeners();
  }

  void setFeedOrder(FeedOrder order) {
    if (_feedOrder == order) return;
    _feedOrder = order;
    notifyListeners();
  }

  Future<void> loadData({
    String? userBikeModel,
    String? currentUserId,
    String? pilotTypeParam,
    String? hashtagParam,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final pilotType = pilotTypeParam ?? (_pilotFilter == FeedPilotFilter.delivery ? 'delivery' : _pilotFilter == FeedPilotFilter.lazer ? 'lazer' : null);
      final results = await Future.wait([
        SocialService.getPosts(
          userBikeModel: userBikeModel,
          currentUserId: currentUserId,
          pilotTypeFilter: pilotType,
          hashtag: _hashtagFilter.isNotEmpty ? _hashtagFilter : null,
        ),
        SocialService.getStories(),
        SocialService.getFollowingIds(),
      ]);
      _posts = results[0] as List<Post>;
      _stories = results[1] as List<Story>;
      _followingIds.clear();
      _followingIds.addAll((results[2] as List<String>));
    } catch (_) {
      // manter listas atuais
    }
    _loading = false;
    notifyListeners();
  }

  int getLikeCount(Post post) {
    if (_likeCountOverrides.containsKey(post.id)) {
      return _likeCountOverrides[post.id]!;
    }
    return SocialService.getPostLikeCount(post);
  }

  bool isPostLiked(Post post) => SocialService.isPostLiked(post.id);

  Future<void> toggleLike(Post post) async {
    final currentCount = getLikeCount(post);
    final newCount = await SocialService.togglePostLike(
      post.id,
      currentLikeCount: currentCount,
    );
    _likeCountOverrides[post.id] = newCount;
    notifyListeners();
  }

  void removePost(String postId) {
    _posts = _posts.where((p) => p.id != postId).toList();
    _likeCountOverrides.remove(postId);
    notifyListeners();
  }

  void replacePost(Post updated) {
    final i = _posts.indexWhere((p) => p.id == updated.id);
    if (i >= 0) {
      _posts[i] = updated;
      notifyListeners();
    }
  }

  void prependPost(Post post) {
    _posts = [post, ..._posts];
    notifyListeners();
  }

  void prependStory(Story story) {
    _stories = [story, ..._stories];
    notifyListeners();
  }

  void removeStory(String storyId) {
    _stories = _stories.where((s) => s.id != storyId).toList();
    notifyListeners();
  }

  void removeProfileStory(String userId, String storyId) {
    final list = _profileStories[userId];
    if (list != null) {
      _profileStories[userId] = list.where((s) => s.id != storyId).toList();
      notifyListeners();
    }
  }

  /// Carrega posts, stories e perfil de um utilizador específico.
  Future<void> loadProfileData(
    String userId, {
    String? currentUserId,
  }) async {
    _profileLoading[userId] = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        SocialService.fetchPostsByUserId(userId, currentUserId: currentUserId),
        SocialService.fetchStoriesByUserId(userId),
        SocialService.checkFollowStatus(
          currentUserId ?? '',
          userId,
        ),
        ApiService.getUserProfile(userId),
      ]);
      _profilePosts[userId] = results[0] as List<Post>;
      _profileStories[userId] = results[1] as List<Story>;
      _isFollowing[userId] = results[2] as bool;
      _profileUserData[userId] = results[3] as Map<String, dynamic>? ?? {};
    } catch (_) {
      _profilePosts[userId] = [];
      _profileStories[userId] = [];
      _profileUserData[userId] = {};
    }
    _profileLoading[userId] = false;
    notifyListeners();
  }

  /// Alterna seguir/deixar de seguir. Atualiza estado em tempo real.
  Future<void> toggleFollow(
    String currentUserId,
    String targetUserId,
  ) async {
    final currentlyFollowing = _isFollowing[targetUserId] ?? false;
    _isFollowing[targetUserId] = !currentlyFollowing;
    notifyListeners();
    try {
      if (currentlyFollowing) {
        await SocialService.unfollowUser(currentUserId, targetUserId);
        _followingIds.remove(targetUserId);
      } else {
        await SocialService.followUser(currentUserId, targetUserId);
        _followingIds.add(targetUserId);
      }
    } catch (_) {
      _isFollowing[targetUserId] = currentlyFollowing;
      notifyListeners();
    }
  }

  /// Atualiza _followingIds quando o utilizador passa a seguir alguém (chamado externamente).
  void addFollowing(String targetUserId) {
    _followingIds.add(targetUserId);
    _isFollowing[targetUserId] = true;
    notifyListeners();
  }

  void removeFollowing(String targetUserId) {
    _followingIds.remove(targetUserId);
    _isFollowing[targetUserId] = false;
    notifyListeners();
  }
}
