class Post {
  final String id;
  final String userId;
  final String userName;
  final String userBikeModel;
  final String? userAvatarUrl;
  final String content;
  final List<String>? images;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool isSameBike; // Se o usuário tem a mesma moto

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userBikeModel,
    this.userAvatarUrl,
    required this.content,
    this.images,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.isSameBike = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userBikeModel: json['userBikeModel'] as String? ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likes: (json['likes'] as int?) ?? 0,
      comments: (json['comments'] as int?) ?? 0,
      isSameBike: json['isSameBike'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userBikeModel': userBikeModel,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'isSameBike': isSameBike,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userBikeModel,
    String? userAvatarUrl,
    String? content,
    List<String>? images,
    DateTime? createdAt,
    int? likes,
    int? comments,
    bool? isSameBike,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userBikeModel: userBikeModel ?? this.userBikeModel,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isSameBike: isSameBike ?? this.isSameBike,
    );
  }
}
