import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_navigator_key.dart';
import '../models/chat_conversation.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/social/notifications_screen.dart';
import 'api_service.dart';

bool _firebaseReady = false;

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
const String _channelId = 'giro_certo_alerts';
const String _channelName = 'Notificações Giro Certo';
const String _channelDescription = 'Mensagens, pedidos de amizade e atividade';
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  _channelId,
  _channelName,
  description: _channelDescription,
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

/// Se o Firebase foi inicializado (necessário para FCM).
bool get isFirebaseReady => _firebaseReady;

/// Inicialização do Firebase (para FCM). Se falhar, a app continua sem push.
Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    _firebaseReady = true;
    // Log simples para validar inicialização do Firebase/FCM.
    // ignore: avoid_print
    print('✅ Firebase inicializado para FCM');
    await _initLocalNotifications();
    return true;
  } catch (e) {
    // ignore: avoid_print
    print('❌ Falha ao inicializar Firebase: $e');
    return false;
  }
}

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(requestAlertPermission: false);
  await _localNotifications.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (NotificationResponse r) {
      if (r.payload != null && r.payload!.isNotEmpty) {
        try {
          final data = json.decode(r.payload!) as Map<String, dynamic>;
          _navigateFromNotification(Map<String, dynamic>.from(data));
        } catch (_) {}
      }
    },
  );
  if (Platform.isAndroid) {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }
}

/// Pedir permissão e obter token FCM; envia o token para a API.
Future<void> requestPermissionAndRegisterToken() async {
  if (!_firebaseReady) return;
  try {
    final messaging = FirebaseMessaging.instance;
    // Android 13+ também exige permissão explícita; usar a mesma API
    // em ambas as plataformas evita divergências.
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // ignore: avoid_print
    print('🔔 Permissão de notificação FCM: ${settings.authorizationStatus}');

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      // Log do token para testes manuais no Firebase Console.
      // ignore: avoid_print
      print('📲 FCM Token: $token');
      await ApiService.registerFcmToken(token);
    } else {
      // ignore: avoid_print
      print('⚠️ FCM Token vazio ou nulo');
    }
  } catch (e) {
    // ignore: avoid_print
    print('❌ Erro ao registar token FCM: $e');
  }
}

void _navigateFromNotification(Map<String, dynamic> data) {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;
  final type = data['type'] as String?;
  if (type == 'chat') {
    final chatId = data['chatId'] as String?;
    if (chatId != null && chatId.isNotEmpty) {
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          initialConversation: ChatConversation(
            id: chatId,
            title: 'Mensagens',
            lastMessagePreview: '',
            lastMessageAt: null,
            isGroup: false,
            imageUrlOrUserId: null,
          ),
        ),
      ));
    }
  } else if (type == 'delivery_offer') {
    // Para corrida nova, apenas abrir a app e manter no fluxo principal.
    // A Home irá puxar pendências e mostrar o card de corrida automaticamente.
    return;
  } else {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => const NotificationsScreen(),
    ));
  }
}

/// Mostrar notificação local quando a app está em primeiro plano (para o telemóvel apitar).
Future<void> _showForegroundNotification(String title, String body, Map<String, dynamic> data) async {
  try {
    final payload = json.encode(data);
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(presentAlert: true, presentSound: true);
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(0x7FFFFFFF),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  } catch (_) {}
}

/// Configura handlers para quando o utilizador toca na notificação (abrir chat ou notificações).
void setupPushNotificationHandlers() {
  if (!_firebaseReady) return;
  // App em primeiro plano: FCM envia aqui; mostramos notificação local para o telemóvel apitar
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final data = message.data.isNotEmpty ? Map<String, dynamic>.from(message.data) : <String, dynamic>{};
    final title = message.notification?.title ?? 'Giro Certo';
    final body = message.notification?.body ?? '';
    _showForegroundNotification(title, body, data);
  });
  // Utilizador tocou na notificação (app em background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data.isNotEmpty) {
      _navigateFromNotification(Map<String, dynamic>.from(message.data));
    }
  });
}

/// Se a app foi aberta ao tocar numa notificação (app estava terminada), navega e retorna true.
Future<bool> handleInitialNotification() async {
  if (!_firebaseReady) return false;
  try {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message?.data != null && message!.data.isNotEmpty) {
      _navigateFromNotification(Map<String, dynamic>.from(message.data));
      return true;
    }
  } catch (_) {}
  return false;
}
