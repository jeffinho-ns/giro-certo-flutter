import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../providers/app_state_provider.dart';

class NotificationsSidebar extends StatefulWidget {
  const NotificationsSidebar({super.key});

  @override
  State<NotificationsSidebar> createState() => _NotificationsSidebarState();
}

class _NotificationsSidebarState extends State<NotificationsSidebar> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  StreamSubscription<Map<String, dynamic>>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _notificationSub = RealtimeService.instance.onNotification.listen((payload) {
      if (!mounted) return;
      if (payload['id'] != null && payload['title'] != null) {
        setState(() {
          _notifications.insert(0, {
            'id': payload['id'],
            'title': payload['title'] ?? 'Alerta',
            'message': payload['message'] ?? '',
            'time': payload['createdAt'] != null ? DateTime.tryParse(payload['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
            'type': 'update',
            'read': false,
          });
        });
      } else {
        _loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alerts = await ApiService.getAlerts(limit: 50);
      
      // Converter alertas para formato de notificação
      final notifications = alerts.map((alert) {
        return {
          'id': alert['id'],
          'title': alert['title'] ?? 'Alerta',
          'message': alert['message'] ?? '',
          'time': DateTime.parse(alert['createdAt'] as String),
          'type': _mapAlertTypeToNotificationType(alert['type'] as String?),
          'read': alert['isRead'] as bool? ?? false,
        };
      }).toList();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar notificações: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _mapAlertTypeToNotificationType(String? alertType) {
    switch (alertType) {
      case 'DOCUMENT_EXPIRING':
        return 'maintenance';
      case 'MAINTENANCE_CRITICAL':
        return 'maintenance';
      case 'PAYMENT_OVERDUE':
        return 'payment';
      default:
        return 'update';
    }
  }

  Future<void> _markAsRead(String alertId) async {
    try {
      await ApiService.markAlertAsRead(alertId);
      _loadNotifications(); // Recarregar
    } catch (e) {
      print('Erro ao marcar notificação como lida: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                            '${_notifications.where((n) => !(n['read'] as bool)).length} não lidas',
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.bell,
                                  size: 48,
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma notificação',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              final alertId = notification['id'] as String?;
                              final isRead = notification['read'] as bool;
                              
                              return _buildNotificationCard(
                                context: context,
                                theme: theme,
                                title: notification['title'] as String,
                                message: notification['message'] as String,
                                time: notification['time'] as DateTime,
                                type: notification['type'] as String,
                                isRead: isRead,
                                alertId: alertId,
                                onTap: () {
                                  if (!isRead && alertId != null) {
                                    _markAsRead(alertId);
                                  }
                                },
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
    String? alertId,
    VoidCallback? onTap,
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

    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
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

