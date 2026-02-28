import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

/// Payload recebido em tempo real para uma nova mensagem de chat.
class ChatMessagePayload {
  final String chatId;
  final Map<String, dynamic> message;

  const ChatMessagePayload({required this.chatId, required this.message});
}

/// Serviço de tempo real (Socket.io): chat e notificações.
/// Conectar após login; desconectar no logout.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;
  final _chatMessageController = StreamController<ChatMessagePayload>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessagePayload> get onChatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// URL do socket (mesmo host da API, sem /api).
  static String get _socketUrl {
    final base = ApiService.baseUrl;
    final uri = Uri.parse(base);
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  }

  void connect(String userId) {
    if (_socket?.connected == true) {
      if (_socket!.id != null) return;
      disconnect();
    }
    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('auth', {'userId': userId});
    });

    _socket!.on('chat:message', (data) {
      if (data is! Map) return;
      final chatId = data['chatId'] as String?;
      final message = data['message'];
      if (chatId != null && message is Map) {
        _chatMessageController.add(ChatMessagePayload(
          chatId: chatId,
          message: Map<String, dynamic>.from(message),
        ));
      }
    });

    _socket!.on('notification', (data) {
      if (data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) {});
    _socket!.onConnectError((e) {});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _chatMessageController.close();
    _notificationController.close();
  }
}
