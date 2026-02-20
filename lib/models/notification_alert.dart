import 'package:flutter/material.dart' show IconData;
import 'package:lucide_icons/lucide_icons.dart';

/// Destino da notificação (rede ou comunidade).
enum NotificationTarget {
  network,
  community,
}

/// Tipo de aviso (igual para rede e comunidade).
enum NotificationAlertType {
  needHelp,
  bikeStopped,
  accident,
  blitz,
}

extension NotificationAlertTypeExt on NotificationAlertType {
  String get label {
    switch (this) {
      case NotificationAlertType.needHelp:
        return 'Preciso de ajuda com a minha moto';
      case NotificationAlertType.bikeStopped:
        return 'Moto parada na estrada';
      case NotificationAlertType.accident:
        return 'Acidente na estrada';
      case NotificationAlertType.blitz:
        return 'Blits fiscalização';
    }
  }

  String get apiValue {
    switch (this) {
      case NotificationAlertType.needHelp:
        return 'need_help';
      case NotificationAlertType.bikeStopped:
        return 'bike_stopped';
      case NotificationAlertType.accident:
        return 'accident';
      case NotificationAlertType.blitz:
        return 'blitz';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationAlertType.needHelp:
        return LucideIcons.helpCircle;
      case NotificationAlertType.bikeStopped:
        return LucideIcons.bike;
      case NotificationAlertType.accident:
        return LucideIcons.alertTriangle;
      case NotificationAlertType.blitz:
        return LucideIcons.shieldAlert;
    }
  }
}
