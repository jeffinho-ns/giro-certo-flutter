import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_navigator_key.dart';
import '../models/chat_conversation.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/social/notifications_screen.dart';
import '../utils/delivery_offer_navigation.dart';

/// Serviço centralizado para notificações locais.
///
/// Usado tanto para eventos em tempo real (Socket.io) como,
/// opcionalmente, para integrações com FCM em foreground.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Canal de alta importância para Android (banner heads‑up).
const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notificações importantes',
  description: 'Usado para mensagens de chat e alertas importantes.',
  importance: Importance.max,
  playSound: true,
);

/// Trata o payload vindo de uma notificação local quando o utilizador toca nela.
///
/// Formatos suportados:
/// - 'chat:<chatId>' → abre o ecrã de chat
/// - 'notification'  → abre o ecrã de notificações gerais
void _handleLocalNotificationPayload(String payload) {
  if (payload.startsWith('delivery_offer:')) {
    final orderId = payload.substring('delivery_offer:'.length).trim();
    if (orderId.isNotEmpty) {
      unawaited(openDeliveryOfferFromNotificationTap(orderId));
    }
    return;
  }

  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  if (payload.startsWith('chat:')) {
    final chatId = payload.substring('chat:'.length);
    if (chatId.isEmpty) return;

    navigator.push(
      MaterialPageRoute<void>(
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
      ),
    );
  } else if (payload == 'notification') {
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }
}

/// Inicializa o plugin de notificações locais e o canal Android.
Future<void> initializeLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const darwinInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: darwinInit,
    macOS: darwinInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        _handleLocalNotificationPayload(payload);
      }
    },
  );

  // Garante canal de alta importância no Android.
  final androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidImplementation != null) {
    await androidImplementation.createNotificationChannel(highImportanceChannel);
  }
}

/// Exibe uma notificação local simples.
Future<void> showLocalNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  final androidDetails = AndroidNotificationDetails(
    highImportanceChannel.id,
    highImportanceChannel.name,
    channelDescription: highImportanceChannel.description,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const darwinDetails = DarwinNotificationDetails();

  final notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
    macOS: darwinDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: notificationDetails,
    payload: payload,
  );
}

