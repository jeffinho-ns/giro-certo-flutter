import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../utils/colors.dart';
import 'profile_page.dart';

/// Tela full-screen de notificações (alertas do usuário).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getAlerts(limit: 50);
      if (mounted) setState(() {
        _alerts = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Erro ao carregar notificações.';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
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
    if (mounted) {
      if (success) _loadAlerts();
    }
  }

  Future<void> _rejectFollowRequest(String requestId) async {
    final success = await ApiService.rejectFollowRequest(requestId);
    if (mounted && success) _loadAlerts();
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
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: _loadAlerts,
            ),
        ],
      ),
      body: _loading
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

                          return ListTile(
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
                            trailing: isFollowRequest && requestId != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: () => _rejectFollowRequest(requestId),
                                        child: const Text('Rejeitar'),
                                      ),
                                      const SizedBox(width: 4),
                                      FilledButton(
                                        onPressed: () => _acceptFollowRequest(
                                          context,
                                          requestId,
                                          requesterName,
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.racingOrange,
                                        ),
                                        child: const Text('Aceitar'),
                                      ),
                                    ],
                                  )
                                : null,
                            onTap: isFollowRequest && requesterId != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProfilePage(
                                          userId: requesterId,
                                          userName: requesterName,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
    );
  }
}
