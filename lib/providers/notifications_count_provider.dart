import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';

/// Contagem de notificações não lidas (badge no ícone). Atualiza em tempo real.
class NotificationsCountProvider extends ChangeNotifier {
  int _unreadCount = 0;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _subscribed = false;

  int get unreadCount => _unreadCount;

  void _updateBadge() {
    try {
      AppBadgePlus.updateBadge(_unreadCount > 0 ? _unreadCount : 0);
    } catch (_) {}
  }

  /// Carregar contagem da API (chamar ao iniciar e ao abrir ecrã de notificações).
  Future<void> loadFromApi() async {
    final count = await ApiService.getAlertsUnreadCount();
    if (_unreadCount != count) {
      _unreadCount = count;
      _updateBadge();
      notifyListeners();
    }
  }

  /// Definir contagem diretamente (ex.: após marcar todas como lidas).
  void setUnreadCount(int count) {
    if (_unreadCount == count) return;
    _unreadCount = count < 0 ? 0 : count;
    _updateBadge();
    notifyListeners();
  }

  /// Incrementar em 1 (quando chega notificação em tempo real).
  void incrementUnread() {
    _unreadCount += 1;
    _updateBadge();
    notifyListeners();
  }

  /// Decrementar em 1 (quando o utilizador marca uma como lida).
  void decrementUnread() {
    if (_unreadCount <= 0) return;
    _unreadCount -= 1;
    _updateBadge();
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

  /// Cancelar subscrição e limpar badge (ex.: no logout).
  void unsubscribe() {
    _sub?.cancel();
    _sub = null;
    _subscribed = false;
    _unreadCount = 0;
    _updateBadge();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
