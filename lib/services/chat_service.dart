import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'api_service.dart';

/// Tipo de lista de conversas (comunidade, grupos, particular).
enum ChatListType {
  community,
  groups,
  privateChat,
}

/// Serviço de chat. Só dados da API — sem conversas inventadas.
class ChatService {
  static Future<List<ChatConversation>> getConversations(
    ChatListType type,
  ) async {
    final requestedType = switch (type) {
      ChatListType.groups || ChatListType.community => 'group',
      ChatListType.privateChat => 'private',
    };
    final list = await ApiService.getChatConversations(type: requestedType);
    final conversations = list.map(_convFromMap).toList();
    switch (type) {
      case ChatListType.privateChat:
        return conversations.where((c) => !c.isGroup).toList();
      case ChatListType.groups:
      case ChatListType.community:
        return conversations.where((c) => c.isGroup).toList();
    }
  }

  static ChatConversation _convFromMap(Map<String, dynamic> j) =>
      ChatConversation(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] as String?) ?? '',
        lastMessagePreview: (j['lastMessagePreview'] as String?) ?? '',
        lastMessageAt: j['lastMessageAt'] != null
            ? DateTime.tryParse(j['lastMessageAt'] as String)
            : null,
        isGroup: (j['isGroup'] as bool?) ??
            (j['type']?.toString().toLowerCase() == 'group'),
        imageUrlOrUserId: j['imageUrlOrUserId'] as String?,
      );

  static Future<List<ChatMessage>> getMessages(String chatId) async {
    final list = await ApiService.getChatMessages(chatId);
    return list.map(_msgFromMap).toList();
  }

  static ChatMessage _msgFromMap(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] ?? '').toString(),
        senderId: (j['senderId'] ?? '').toString(),
        senderName: (j['senderName'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
        isFromMe: (j['isFromMe'] as bool?) ?? false,
      );

  static Future<ChatMessage> sendMessage({
    required String chatId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    final j = await ApiService.sendChatMessage(chatId, text);
    return _msgFromMap(j);
  }

  static Future<void> deleteConversation(String chatId) async {
    await ApiService.deleteChatConversation(chatId);
  }

  static Future<Map<String, dynamic>> getChatSettings(String chatId) async {
    try {
      return await ApiService.getChatSettings(chatId);
    } catch (_) {
      return {};
    }
  }

  static Future<void> setChatMuted(String chatId, bool muted) async {
    await ApiService.updateChatMute(chatId, muted);
  }

  static Future<ChatConversation> getOrCreatePrivateChat({
    required String currentUserId,
    required String recipientId,
    required String recipientName,
    String? recipientPhotoUrl,
  }) async {
    final j = await ApiService.getOrCreatePrivateChat(recipientId);
    return _convFromMap(j);
  }

  static Future<ChatConversation> startSupportChat({
    required String currentUserId,
  }) async {
    final j = await ApiService.startSupportChat();
    return _convFromMap(j);
  }
}
