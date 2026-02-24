/// Representa um story (história) na rede social.
class Story {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  /// URL da imagem ou asset path da mídia do story.
  final String mediaUrl;
  final DateTime createdAt;
  final int likeCount;
  /// Legenda/texto opcional da story.
  final String? caption;

  const Story({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.mediaUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.caption,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      mediaUrl: json['mediaUrl'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likeCount: (json['likeCount'] as int?) ?? 0,
      caption: json['caption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'mediaUrl': mediaUrl,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      if (caption != null) 'caption': caption,
    };
  }
}
