import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

/// Tipo de lista de conversas (comunidade, grupos, particular).
enum ChatListType {
  community,
  groups,
  privateChat,
}

/// Serviço de chat. Mock local; preparado para API (ex.: GET/POST /chats, /chats/:id/messages).
class ChatService {
  /// Lista conversas por tipo.
  static Future<List<ChatConversation>> getConversations(
    ChatListType type,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    switch (type) {
      case ChatListType.community:
        return _mockCommunity;
      case ChatListType.groups:
        return _mockGroups;
      case ChatListType.privateChat:
        return _mockPrivate;
    }
  }

  /// Mensagens de uma conversa (mock; em produção GET /chats/:id/messages).
  static Future<List<ChatMessage>> getMessages(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list = _mockMessages[chatId];
    return List.from(list ?? []);
  }

  /// Envia mensagem (mock: adiciona à lista local; em produção POST /chats/:id/messages).
  static Future<ChatMessage> sendMessage({
    required String chatId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final msg = ChatMessage(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      senderId: userId,
      senderName: userName,
      text: text,
      createdAt: DateTime.now(),
      isFromMe: true,
    );
    _mockMessages.putIfAbsent(chatId, () => []).add(msg);
    return msg;
  }

  static final List<ChatConversation> _mockCommunity = [
    ChatConversation(
      id: 'comm_1',
      title: 'Comunidade CB 650F',
      lastMessagePreview: 'Última: Boa noite a todos!',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
      isGroup: true,
    ),
  ];

  static final List<ChatConversation> _mockGroups = [
    ChatConversation(
      id: 'grp_1',
      title: 'Passeio domingo',
      lastMessagePreview: 'Maria: Combinado às 8h',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 30)),
      isGroup: true,
    ),
    ChatConversation(
      id: 'grp_2',
      title: 'Manutenção moto',
      lastMessagePreview: 'João: Alguém indica oficina?',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
      isGroup: true,
    ),
  ];

  static final List<ChatConversation> _mockPrivate = [
    ChatConversation(
      id: 'pv_1',
      title: 'Maria Santos',
      lastMessagePreview: 'Obrigada pela dica!',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isGroup: false,
    ),
    ChatConversation(
      id: 'pv_2',
      title: 'João Costa',
      lastMessagePreview: 'Amanhã combino contigo',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
      isGroup: false,
    ),
  ];

  static final Map<String, List<ChatMessage>> _mockMessages = {
    'comm_1': [
      ChatMessage(
        id: '1',
        senderId: 'u2',
        senderName: 'Maria',
        text: 'Oi! Alguém vai no passeio domingo?',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isFromMe: false,
      ),
      ChatMessage(
        id: '2',
        senderId: 'me',
        senderName: 'Você',
        text: 'Eu vou! Às 8h no posto.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isFromMe: true,
      ),
      ChatMessage(
        id: '3',
        senderId: 'u3',
        senderName: 'João',
        text: 'Combinado, até lá.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isFromMe: false,
      ),
    ],
    'grp_1': [],
    'grp_2': [],
    'pv_1': [],
    'pv_2': [],
  };
}
