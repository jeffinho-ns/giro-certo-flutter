import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import '../models/delivery_offer_payload.dart';
import 'api_service.dart';
import 'notification_service.dart';

/// Payload recebido em tempo real para uma nova mensagem de chat.
class ChatMessagePayload {
  final String chatId;
  final Map<String, dynamic> message;

  const ChatMessagePayload({required this.chatId, required this.message});
}

class RiderLocationPayload {
  final String userId;
  final double lat;
  final double lng;
  final String? orderId;
  final String? status;

  const RiderLocationPayload({
    required this.userId,
    required this.lat,
    required this.lng,
    this.orderId,
    this.status,
  });
}

/// Serviço de tempo real (Socket.io): chat e notificações.
/// Conectar após login; desconectar no logout.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;
  String? _connectedUserId;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  int _lastRiderLocationEmitMs = 0;
  /// Intervalo único (Torre de Controle): 4 s — evita flood no Node/Render.
  static const int riderLocationEmitIntervalMs = 4000;

  final _chatMessageController =
      StreamController<ChatMessagePayload>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _riderLocationController =
      StreamController<RiderLocationPayload>.broadcast();
  final _deliveryOfferController =
      StreamController<DeliveryOfferPayload>.broadcast();

  Stream<ChatMessagePayload> get onChatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get onDeliveryStatusChanged =>
      _deliveryStatusController.stream;
  Stream<RiderLocationPayload> get onRiderLocationUpdate =>
      _riderLocationController.stream;
  Stream<DeliveryOfferPayload> get onDeliveryNewOrderOffer =>
      _deliveryOfferController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// URL do socket (mesmo host da API, sem /api).
  static String get _socketUrl {
    final base = ApiService.baseUrl;
    final uri = Uri.parse(base);
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  }

  void connect(String userId) {
    _connectedUserId = userId;
    if (_socket?.connected == true && _socket?.id != null) {
      return;
    }
    disconnect(clearUserId: false);
    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) async {
      final token = await ApiService.getStoredToken();
      _socket!.emit('auth', {
        'userId': userId,
        if (token != null && token.isNotEmpty) 'token': token,
      });
    });

    _socket!.on('chat:message', (data) {
      if (data is! Map) return;
      final chatId = data['chatId'] as String?;
      final message = data['message'];
      if (chatId != null && message is Map) {
        final messageMap = Map<String, dynamic>.from(message);
        _chatMessageController.add(ChatMessagePayload(
          chatId: chatId,
          message: messageMap,
        ));

        // Notificação local em foreground para novas mensagens.
        final preview = (messageMap['text'] as String?) ??
            (messageMap['content'] as String?) ??
            (messageMap['body'] as String?) ??
            '';
        final body =
            preview.isNotEmpty ? preview : 'Você recebeu uma nova mensagem.';

        showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Nova mensagem',
          body: body,
          payload: 'chat:$chatId',
        );
      }
    });

    _socket!.on('notification', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _notificationController.add(map);

        final title = (map['title'] as String?) ?? 'Nova notificação';
        final body = (map['body'] as String?) ??
            (map['description'] as String?) ??
            'Você recebeu uma nova notificação.';

        showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: 'notification',
        );
      }
    });

    _socket!.on('delivery:race:lost', (data) {
      final map =
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final title = 'Corrida indisponível';
      final body = (map['message'] as String?) ??
          'Essa corrida já foi aceita por outro entregador.';
      _notificationController.add({
        'type': 'delivery_race_lost',
        ...map,
      });
      showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: 'delivery_race_lost',
      );
    });

    _socket!.on('delivery:status:changed', (data) {
      if (data is Map) {
        _deliveryStatusController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('delivery:update', (data) {
      if (data is Map) {
        _deliveryStatusController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('delivery:new_order_offer', (data) {
      if (data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      final orderRaw = map['order'];
      if (orderRaw is! Map) return;
      try {
        final order = ApiService.riderDeliveryOrderFromJson(
          Map<String, dynamic>.from(orderRaw),
        );
        final expires = map['expiresInSeconds'];
        final distanceToStore = map['distanceToStoreKm'];
        final routeDistance = map['routeDistanceKm'];
        _deliveryOfferController.add(
          DeliveryOfferPayload(
            order: order,
            expiresInSeconds: expires is num ? expires.toInt() : 15,
            distanceToStoreKm: distanceToStore is num
                ? distanceToStore.toDouble()
                : double.tryParse('$distanceToStore'),
            routeDistanceKm: routeDistance is num
                ? routeDistance.toDouble()
                : double.tryParse('$routeDistance'),
          ),
        );
      } catch (e) {
        debugPrint('delivery:new_order_offer parse: $e');
      }
    });
    _socket!.on('rider:location:update', (data) {
      if (data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      final userId = map['userId'] as String?;
      final lat =
          map['lat'] is num ? (map['lat'] as num).toDouble() : double.tryParse('${map['lat']}');
      final lng =
          map['lng'] is num ? (map['lng'] as num).toDouble() : double.tryParse('${map['lng']}');
      if (userId == null || lat == null || lng == null) return;
      _riderLocationController.add(
        RiderLocationPayload(
          userId: userId,
          lat: lat,
          lng: lng,
          orderId: map['orderId'] as String?,
          status: map['status'] as String?,
        ),
      );
    });

    _socket!.onDisconnect((_) {
      _scheduleSilentReconnect();
    });
    _socket!.onConnect((_) {
      _reconnectAttempt = 0;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    });
    _socket!.onConnectError((_) {
      _scheduleSilentReconnect();
    });
  }

  void _scheduleSilentReconnect() {
    if (_connectedUserId == null) return;
    if (_reconnectTimer != null) return;
    _reconnectAttempt += 1;
    final waitSec = (_reconnectAttempt * 2).clamp(2, 20);
    _reconnectTimer = Timer(Duration(seconds: waitSec), () {
      _reconnectTimer = null;
      final userId = _connectedUserId;
      if (userId == null) return;
      connect(userId);
    });
  }

  /// Emite posição para a Torre de Controle via Socket.io (throttle ~4 s).
  /// A persistência no PostgreSQL é feita no servidor ao receber `rider:location`.
  void emitRiderLocationThrottled({
    required double lat,
    required double lng,
    String? orderId,
    String? orderStatus,
  }) {
    if (_socket?.connected != true || _connectedUserId == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastRiderLocationEmitMs < riderLocationEmitIntervalMs) return;
    _lastRiderLocationEmitMs = now;
    _socket!.emit('rider:location', {
      'userId': _connectedUserId,
      'lat': lat,
      'lng': lng,
      if (orderId != null) 'orderId': orderId,
      if (orderStatus != null) 'status': orderStatus,
      'at': now,
    });
  }

  /// Uma emissão imediata (ex.: após marco da corrida + PUT), sem esperar o intervalo normal.
  void emitRiderLocationImmediate({
    required double lat,
    required double lng,
    String? orderId,
    String? orderStatus,
  }) {
    if (_socket?.connected != true || _connectedUserId == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastRiderLocationEmitMs = now;
    _socket!.emit('rider:location', {
      'userId': _connectedUserId,
      'lat': lat,
      'lng': lng,
      if (orderId != null) 'orderId': orderId,
      if (orderStatus != null) 'status': orderStatus,
      'at': now,
      'checkpoint': true,
    });
  }

  void setNavigationMode(bool enabled, {String? orderId}) {
    if (enabled && orderId != null && orderId.isNotEmpty) {
      joinOrderTracking(orderId);
    }
  }

  void joinOrderTracking(String orderId) {
    if (_socket?.connected != true) return;
    _socket!.emit('tracking:join-order', {'orderId': orderId});
  }

  void leaveOrderTracking(String orderId) {
    if (_socket?.connected != true) return;
    _socket!.emit('tracking:leave-order', {'orderId': orderId});
  }

  void disconnect({bool clearUserId = true}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    if (clearUserId) {
      _connectedUserId = null;
    }
  }

  void dispose() {
    disconnect(clearUserId: true);
    _chatMessageController.close();
    _notificationController.close();
    _deliveryStatusController.close();
    _riderLocationController.close();
    _deliveryOfferController.close();
  }
}
