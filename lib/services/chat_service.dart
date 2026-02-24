import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'api_service.dart';

/// Tipo de lista de conversas (comunidade, grupos, particular).
enum ChatListType {
  community,
  groups,
  privateChat,
}

/// Serviço de chat. Usa API quando disponível; fallback para mock.
class ChatService {
  /// Lista conversas por tipo. Apenas privateChat usa API real.
  static Future<List<ChatConversation>> getConversations(
    ChatListType type,
  ) async {
    if (type == ChatListType.privateChat) {
      try {
        final list = await ApiService.getChatConversations();
        return list.map(_convFromMap).toList();
      } catch (_) {
        return _mockPrivate;
      }
    }
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

  static ChatConversation _convFromMap(Map<String, dynamic> j) => ChatConversation(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        lastMessagePreview: (j['lastMessagePreview'] as String?) ?? '',
        lastMessageAt: j['lastMessageAt'] != null
            ? DateTime.tryParse(j['lastMessageAt'] as String)
            : null,
        isGroup: (j['isGroup'] as bool?) ?? false,
        imageUrlOrUserId: j['imageUrlOrUserId'] as String?,
      );

  /// Mensagens de uma conversa.
  static Future<List<ChatMessage>> getMessages(String chatId) async {
    try {
      final list = await ApiService.getChatMessages(chatId);
      return list.map(_msgFromMap).toList();
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 150));
      final list = _mockMessages[chatId];
      return List.from(list ?? []);
    }
  }

  static ChatMessage _msgFromMap(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        senderId: j['senderId'] as String,
        senderName: (j['senderName'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
        isFromMe: (j['isFromMe'] as bool?) ?? false,
      );

  /// Envia mensagem.
  static Future<ChatMessage> sendMessage({
    required String chatId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    try {
      final j = await ApiService.sendChatMessage(chatId, text);
      return _msgFromMap(j);
    } catch (_) {
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

  /// Obtém ou cria uma conversa particular com o destinatário.
  /// Retorna ChatConversation para usar na ChatScreen.
  static Future<ChatConversation> getOrCreatePrivateChat({
    required String currentUserId,
    required String recipientId,
    required String recipientName,
    String? recipientPhotoUrl,
  }) async {
    try {
      final j = await ApiService.getOrCreatePrivateChat(recipientId);
      return _convFromMap(j);
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 100));
      final ids = [currentUserId, recipientId]..sort();
      final chatId = 'pv_${ids[0]}_${ids[1]}';
      try {
        return _mockPrivate.firstWhere(
          (c) => c.id == chatId || c.imageUrlOrUserId == recipientId,
        );
      } catch (_) {}
      return ChatConversation(
        id: chatId,
        title: recipientName,
        lastMessagePreview: '',
        lastMessageAt: null,
        isGroup: false,
        imageUrlOrUserId: recipientId,
      );
    }
  }

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
