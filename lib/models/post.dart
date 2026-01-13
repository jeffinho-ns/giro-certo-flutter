class Post {
  final String id;
  final String userId;
  final String userName;
  final String userBikeModel;
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
    required this.content,
    this.images,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.isSameBike = false,
  });
}
