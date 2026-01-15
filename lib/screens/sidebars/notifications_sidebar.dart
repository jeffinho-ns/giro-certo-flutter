import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';

class NotificationsSidebar extends StatelessWidget {
  const NotificationsSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Notificações mockadas
    final notifications = [
      {
        'title': 'Manutenção de Óleo',
        'message': 'Está na hora de trocar o óleo da sua moto',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'type': 'maintenance',
        'read': false,
      },
      {
        'title': 'Nova Peça Recomendada',
        'message': 'Encontramos uma peça perfeita para sua ${'Honda CB 600F'}',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'type': 'recommendation',
        'read': false,
      },
      {
        'title': 'Atualização do App',
        'message': 'Nova versão disponível com melhorias',
        'time': DateTime.now().subtract(const Duration(days: 2)),
        'type': 'update',
        'read': true,
      },
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.racingOrange,
                            AppColors.racingOrangeLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.bell,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notificações',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${notifications.where((n) {
                              final read = n['read'];
                              return read is bool && read == false;
                            }).length} não lidas',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Lista de notificações
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(
                      context: context,
                      theme: theme,
                      title: notification['title'] as String,
                      message: notification['message'] as String,
                      time: notification['time'] as DateTime,
                      type: notification['type'] as String,
                      isRead: notification['read'] as bool,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String message,
    required DateTime time,
    required String type,
    required bool isRead,
  }) {
    IconData icon;
    Color color;

    switch (type) {
      case 'maintenance':
        icon = LucideIcons.wrench;
        color = AppColors.statusWarning;
        break;
      case 'recommendation':
        icon = LucideIcons.star;
        color = AppColors.racingOrange;
        break;
      case 'update':
        icon = LucideIcons.download;
        color = AppColors.statusOk;
        break;
      default:
        icon = LucideIcons.bell;
        color = AppColors.racingOrange;
    }

    final timeAgo = _getTimeAgo(time);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? theme.cardColor : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead
              ? theme.dividerColor
              : AppColors.racingOrange.withOpacity(0.3),
          width: isRead ? 1 : 1.5,
        ),
        boxShadow: isRead
            ? null
            : [
                BoxShadow(
                  color: AppColors.racingOrange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.racingOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }
}

