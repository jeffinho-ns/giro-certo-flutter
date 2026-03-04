import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../utils/colors.dart';
import '../../providers/notifications_count_provider.dart';
import 'profile_page.dart';

/// Filtro da lista de notificações.
enum _NotificationFilter {
  all,
  unread,
  followRequests,
}

/// Ecrã full-screen de notificações (alertas do utilizador).
/// Filtros, marcar como lida ao clicar (remove da lista), botão marcar todas e excluir por item.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _error;
  _NotificationFilter _filter = _NotificationFilter.unread;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bool? isRead = _filter == _NotificationFilter.unread
          ? false
          : (_filter == _NotificationFilter.all ? null : null);
      final String? type = _filter == _NotificationFilter.followRequests
          ? 'FOLLOW_REQUEST'
          : null;
      final list = await ApiService.getAlerts(
        limit: 50,
        isRead: isRead,
        type: type,
      );
      if (mounted) {
        setState(() {
          _alerts = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar notificações.';
          _loading = false;
        });
      }
    }
  }

  /// Marca uma notificação como lida, remove da lista e atualiza o badge.
  Future<void> _markAsReadAndRemove(Map<String, dynamic> alert) async {
    final id = alert['id'] as String?;
    if (id == null || id.isEmpty) return;
    try {
      await ApiService.markAlertAsRead(id);
      if (mounted) {
        setState(() {
          _alerts.removeWhere((a) => (a['id'] as String?) == id);
        });
        Provider.of<NotificationsCountProvider>(context, listen: false).decrementUnread();
      }
    } catch (_) {}
  }

  /// Marcar todas como lidas e atualizar provider + lista.
  Future<void> _markAllAsRead() async {
    try {
      await ApiService.markAllAlertsAsRead();
      if (mounted) {
        Provider.of<NotificationsCountProvider>(context, listen: false).setUnreadCount(0);
        await _loadAlerts();
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsCountProvider>(context, listen: false).loadFromApi();
    });
    _loadAlerts();
    _notificationSub = RealtimeService.instance.onNotification.listen((payload) {
      if (!mounted) return;
      setState(() {
        if (payload['id'] != null && payload['title'] != null) {
          _alerts.insert(0, Map<String, dynamic>.from(payload));
        } else {
          _loadAlerts();
        }
      });
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _acceptFollowRequest(
    BuildContext context,
    String requestId,
    String? requesterName,
    Map<String, dynamic> alert,
  ) async {
    final followBack = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aceitar pedido'),
        content: Text(
          '${requesterName ?? 'Alguém'} quer seguir-te. Desejas seguir de volta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Só aceitar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.racingOrange),
            child: const Text('Aceitar e seguir de volta'),
          ),
        ],
      ),
    );
    if (followBack == null || !mounted) return;
    final success = await ApiService.acceptFollowRequest(requestId, followBack: followBack);
    if (mounted && success) {
      await _markAsReadAndRemove(alert);
    }
  }

  Future<void> _rejectFollowRequest(String requestId, Map<String, dynamic> alert) async {
    final success = await ApiService.rejectFollowRequest(requestId);
    if (mounted && success) {
      await _markAsReadAndRemove(alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notificações'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_loading && _alerts.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.checkCheck),
              tooltip: 'Marcar todas como lidas',
              onPressed: _markAllAsRead,
            ),
          if (!_loading)
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: _loadAlerts,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filterChip('Não lidas', _NotificationFilter.unread),
                const SizedBox(width: 8),
                _filterChip('Todas', _NotificationFilter.all),
                const SizedBox(width: 8),
                _filterChip('Pedidos de amizade', _NotificationFilter.followRequests),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadAlerts,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _alerts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.bellOff,
                                  size: 64,
                                  color: theme.iconTheme.color?.withOpacity(0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma notificação',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAlerts,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _alerts.length,
                              itemBuilder: (context, i) {
                                final a = _alerts[i];
                                final type = a['type'] as String?;
                                final title = a['title'] as String? ?? 'Alerta';
                                final body = a['body'] as String? ?? a['message'] as String?;
                                final metadata = a['metadata'] as Map<String, dynamic>?;
                                final isFollowRequest = type == 'FOLLOW_REQUEST';
                                final requestId = isFollowRequest
                                    ? (metadata?['followRequestId'] as String?)
                                    : null;
                                final requesterName = isFollowRequest
                                    ? (metadata?['requesterName'] as String?)
                                    : null;
                                final requesterId = isFollowRequest
                                    ? (metadata?['requesterId'] as String?)
                                    : null;

                                return Dismissible(
                                  key: Key((a['id'] as String?) ?? 'item_$i'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: theme.colorScheme.errorContainer,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    child: const Icon(LucideIcons.trash2, color: Colors.white),
                                  ),
                                  onDismissed: (_) => _markAsReadAndRemove(a),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isFollowRequest
                                          ? AppColors.racingOrange.withOpacity(0.2)
                                          : theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        isFollowRequest ? LucideIcons.userPlus : LucideIcons.bell,
                                        color: isFollowRequest
                                            ? AppColors.racingOrange
                                            : theme.colorScheme.onPrimaryContainer,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(title),
                                    subtitle: body != null && body.isNotEmpty
                                        ? Text(body)
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isFollowRequest && requestId != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(LucideIcons.trash2, size: 20),
                                                tooltip: 'Excluir',
                                                onPressed: () => _markAsReadAndRemove(a),
                                              ),
                                              TextButton(
                                                onPressed: () => _rejectFollowRequest(requestId, a),
                                                child: const Text('Rejeitar'),
                                              ),
                                              const SizedBox(width: 4),
                                              FilledButton(
                                                onPressed: () => _acceptFollowRequest(
                                                  context,
                                                  requestId,
                                                  requesterName,
                                                  a,
                                                ),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: AppColors.racingOrange,
                                                ),
                                                child: const Text('Aceitar'),
                                              ),
                                            ],
                                          )
                                        else
                                          IconButton(
                                            icon: const Icon(LucideIcons.trash2, size: 20),
                                            tooltip: 'Excluir',
                                            onPressed: () => _markAsReadAndRemove(a),
                                          ),
                                      ],
                                    ),
                                    onTap: () async {
                                      if (isFollowRequest && requesterId != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProfilePage(
                                              userId: requesterId,
                                              userName: requesterName,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      // Qualquer outra notificação: marcar como lida e remover da lista
                                      await _markAsReadAndRemove(a);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _NotificationFilter value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = value;
          _loadAlerts();
        });
      },
      selectedColor: AppColors.racingOrange.withOpacity(0.3),
      checkmarkColor: AppColors.racingOrange,
    );
  }
}
