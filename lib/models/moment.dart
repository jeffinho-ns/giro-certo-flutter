/// Vídeo curto publicado por um motociclista no feed "Momentos".
/// Funciona como um Reels — vídeo vertical, full-screen, com interações sociais.
class Moment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  /// Perfil do autor — usado para mostrar badge (Delivery/Lazer).
  final String? userPilotProfile;
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final List<String> hashtags;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final int reposts;
  final bool likedByMe;
  final bool repostedByMe;
  final Duration duration;
  /// Se foi repostado por mim a partir de outro usuário, mantemos referência
  /// ao autor original para exibir "Repostado por...".
  final String? originalAuthorName;

  const Moment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.userPilotProfile,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.caption,
    this.hashtags = const [],
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.likedByMe = false,
    this.repostedByMe = false,
    this.duration = Duration.zero,
    this.originalAuthorName,
  });

  Moment copyWith({
    int? likes,
    int? comments,
    int? reposts,
    bool? likedByMe,
    bool? repostedByMe,
  }) {
    return Moment(
      id: id,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userPilotProfile: userPilotProfile,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      hashtags: hashtags,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      reposts: reposts ?? this.reposts,
      likedByMe: likedByMe ?? this.likedByMe,
      repostedByMe: repostedByMe ?? this.repostedByMe,
      duration: duration,
      originalAuthorName: originalAuthorName,
    );
  }

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: (json['userName'] as String?) ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      userPilotProfile: json['userPilotProfile'] as String?,
      videoUrl: (json['videoUrl'] as String?) ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      caption: (json['caption'] as String?) ?? '',
      hashtags: (json['hashtags'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      reposts: (json['reposts'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      repostedByMe: json['repostedByMe'] as bool? ?? false,
      duration: Duration(
        milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0,
      ),
      originalAuthorName: json['originalAuthorName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'userPilotProfile': userPilotProfile,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'hashtags': hashtags,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'comments': comments,
        'reposts': reposts,
        'likedByMe': likedByMe,
        'repostedByMe': repostedByMe,
        'durationMs': duration.inMilliseconds,
        if (originalAuthorName != null)
          'originalAuthorName': originalAuthorName,
      };
}

/// Comentário em um Moment.
class MomentComment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String text;
  final DateTime createdAt;

  const MomentComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.text,
    required this.createdAt,
  });
}
