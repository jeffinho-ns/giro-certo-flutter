import 'package:flutter/material.dart';
import '../services/push_notification_service.dart' as push;
import '../services/realtime_service.dart';

/// Conecta o socket de tempo real quando o utilizador está autenticado.
/// Regista FCM para notificações no telemóvel bloqueado.
class RealtimeConnection extends StatefulWidget {
  final String userId;
  final Widget child;

  const RealtimeConnection({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  State<RealtimeConnection> createState() => _RealtimeConnectionState();
}

class _RealtimeConnectionState extends State<RealtimeConnection> {
  @override
  void initState() {
    super.initState();
    RealtimeService.instance.connect(widget.userId);
    push.requestPermissionAndRegisterToken();
    push.setupPushNotificationHandlers();
    push.handleInitialNotification();
  }

  @override
  void didUpdateWidget(RealtimeConnection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      RealtimeService.instance.disconnect();
      RealtimeService.instance.connect(widget.userId);
    }
  }

  @override
  void dispose() {
    RealtimeService.instance.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
