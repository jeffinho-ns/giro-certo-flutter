import 'post_type.dart';
import 'reaction_type.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String userBikeModel;
  final String? userAvatarUrl;
  /// Perfil do autor: TRABALHO = delivery, outros = piloto lazer (para badge).
  final String? userPilotProfile;
  final String content;
  final List<String>? images;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool isSameBike; // Se o usuário tem a mesma moto
  final PostType postType;
  final List<String> hashtags;
  /// Contagens por tipo de reação (like, boaRota, boaDica).
  final Map<ReactionType, int> reactions;
  final ReactionType? currentUserReaction;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userBikeModel,
    this.userAvatarUrl,
    this.userPilotProfile,
    required this.content,
    this.images,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.isSameBike = false,
    this.postType = PostType.normal,
    this.hashtags = const [],
    this.reactions = const {},
    this.currentUserReaction,
  });

  bool get isDeliveryAuthor =>
      (userPilotProfile ?? '').toUpperCase().trim() == 'TRABALHO';

  factory Post.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'] as Map<String, dynamic>?;
    final Map<ReactionType, int> reactionsMap = {};
    if (rawReactions != null) {
      for (final e in rawReactions.entries) {
        final rt = ReactionTypeExt.fromString(e.key as String?);
        reactionsMap[rt] = (e.value is int) ? e.value : int.tryParse(e.value.toString()) ?? 0;
      }
    }
    final rawHashtags = json['hashtags'];
    List<String> hashtagList = [];
    if (rawHashtags is List) {
      hashtagList = rawHashtags.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } else if (rawHashtags is String && rawHashtags.isNotEmpty) {
      hashtagList = rawHashtags.split(RegExp(r'\s+')).where((s) => s.startsWith('#')).map((s) => s.replaceFirst('#', '')).toList();
    }
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userBikeModel: json['userBikeModel'] as String? ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      userPilotProfile: json['userPilotProfile'] as String?,
      content: json['content'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likes: (json['likes'] as int?) ?? 0,
      comments: (json['comments'] as int?) ?? 0,
      isSameBike: json['isSameBike'] as bool? ?? false,
      postType: PostTypeExt.fromString(json['postType'] as String?),
      hashtags: hashtagList,
      reactions: reactionsMap.isNotEmpty ? reactionsMap : {ReactionType.like: (json['likes'] as int? ?? json['likesCount'] as int?) ?? 0},
      currentUserReaction: json['currentUserReaction'] != null
          ? ReactionTypeExt.fromString(json['currentUserReaction'] as String?)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final reactionsJson = <String, int>{};
    for (final e in reactions.entries) {
      reactionsJson[e.key.apiValue] = e.value;
    }
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userBikeModel': userBikeModel,
      'userAvatarUrl': userAvatarUrl,
      'userPilotProfile': userPilotProfile,
      'content': content,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'isSameBike': isSameBike,
      'postType': postType.apiValue,
      'hashtags': hashtags,
      'reactions': reactionsJson,
      if (currentUserReaction != null) 'currentUserReaction': currentUserReaction!.apiValue,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userBikeModel,
    String? userAvatarUrl,
    String? userPilotProfile,
    String? content,
    List<String>? images,
    DateTime? createdAt,
    int? likes,
    int? comments,
    bool? isSameBike,
    PostType? postType,
    List<String>? hashtags,
    Map<ReactionType, int>? reactions,
    ReactionType? currentUserReaction,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userBikeModel: userBikeModel ?? this.userBikeModel,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      userPilotProfile: userPilotProfile ?? this.userPilotProfile,
      content: content ?? this.content,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isSameBike: isSameBike ?? this.isSameBike,
      postType: postType ?? this.postType,
      hashtags: hashtags ?? this.hashtags,
      reactions: reactions ?? this.reactions,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
    );
  }
}
