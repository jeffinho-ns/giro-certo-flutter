import '../models/notification_alert.dart';
import 'api_service.dart';

/// Serviço de envio de alertas/notificações para a rede ou comunidade.
class NotificationAlertService {
  /// Envia um alerta para a rede inteira ou apenas para a comunidade do utilizador.
  static Future<void> sendAlert({
    required NotificationTarget target,
    required NotificationAlertType alertType,
    required String userId,
    required String userName,
  }) async {
    try {
      await ApiService.postAlertBroadcast(
        target: target == NotificationTarget.network ? 'network' : 'community',
        type: alertType.apiValue,
      );
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 600));
      rethrow;
    }
  }
}
