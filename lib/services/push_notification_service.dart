import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../app_navigator_key.dart';
import '../models/chat_conversation.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/social/notifications_screen.dart';
import 'api_service.dart';

bool _firebaseReady = false;

/// Se o Firebase foi inicializado (necessário para FCM).
bool get isFirebaseReady => _firebaseReady;

/// Inicialização do Firebase (para FCM). Se falhar, a app continua sem push.
Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    _firebaseReady = true;
    return true;
  } catch (_) {
    return false;
  }
}

/// Pedir permissão e obter token FCM; envia o token para a API.
Future<void> requestPermissionAndRegisterToken() async {
  if (!_firebaseReady) return;
  try {
    final messaging = FirebaseMessaging.instance;
    if (Platform.isIOS) {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    }
    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await ApiService.registerFcmToken(token);
    }
  } catch (_) {}
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
  } else {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => const NotificationsScreen(),
    ));
  }
}

/// Configura handlers para quando o utilizador toca na notificação (abrir chat ou notificações).
void setupPushNotificationHandlers() {
  if (!_firebaseReady) return;
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
