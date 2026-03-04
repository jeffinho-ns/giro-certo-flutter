import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';

/// Contagem de notificações não lidas (badge no ícone). Atualiza em tempo real.
class NotificationsCountProvider extends ChangeNotifier {
  int _unreadCount = 0;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _subscribed = false;

  int get unreadCount => _unreadCount;

  /// Carregar contagem da API (chamar ao iniciar e ao abrir ecrã de notificações).
  Future<void> loadFromApi() async {
    final count = await ApiService.getAlertsUnreadCount();
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  /// Incrementar em 1 (quando chega notificação em tempo real).
  void incrementUnread() {
    _unreadCount += 1;
    notifyListeners();
  }

  /// Subscrever ao socket para atualizar a contagem em tempo real (só subscreve uma vez).
  void subscribeToRealtime() {
    if (_subscribed) return;
    _subscribed = true;
    _sub?.cancel();
    _sub = RealtimeService.instance.onNotification.listen((_) {
      incrementUnread();
    });
  }

  /// Cancelar subscrição (ex.: no logout).
  void unsubscribe() {
    _sub?.cancel();
    _sub = null;
    _subscribed = false;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
