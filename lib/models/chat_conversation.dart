/// Conversa de chat (comunidade, grupo ou particular).
class ChatConversation {
  final String id;
  final String title;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final bool isGroup;
  /// Para grupos: URL ou null. Para particular: id do outro usuário.
  final String? imageUrlOrUserId;

  const ChatConversation({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    this.lastMessageAt,
    required this.isGroup,
    this.imageUrlOrUserId,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      isGroup: json['isGroup'] as bool? ?? false,
      imageUrlOrUserId: json['imageUrlOrUserId'] as String?,
    );
  }
}
