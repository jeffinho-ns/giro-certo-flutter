import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../models/story.dart';
import '../services/social_service.dart';

class SocialFeedProvider extends ChangeNotifier {
  List<Post> _posts = [];
  List<Story> _stories = [];
  String _searchQuery = '';
  bool _loading = true;
  final Map<String, int> _likeCountOverrides = {};
  FeedOrder _feedOrder = FeedOrder.recent;

  List<Post> get posts => _posts;
  List<Story> get stories => _stories;
  String get searchQuery => _searchQuery;
  bool get loading => _loading;
  FeedOrder get feedOrder => _feedOrder;

  List<Post> get filteredPosts {
    var list = SocialService.filterPosts(_posts, _searchQuery);
    return SocialService.sortPosts(list, _feedOrder);
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
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
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        SocialService.getPosts(
          userBikeModel: userBikeModel,
          currentUserId: currentUserId,
        ),
        SocialService.getStories(),
      ]);
      _posts = results[0] as List<Post>;
      _stories = results[1] as List<Story>;
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
}
