import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_state_provider.dart';
import '../providers/drawer_provider.dart';
import '../utils/colors.dart';
import '../screens/sidebars/notifications_sidebar.dart';
import '../services/api_service.dart';

class ModernHeader extends StatefulWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ModernHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  State<ModernHeader> createState() => _ModernHeaderState();
}

class _ModernHeaderState extends State<ModernHeader> {
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationsCount();
  }

  Future<void> _loadNotificationsCount() async {
    try {
      final alerts = await ApiService.getAlerts(limit: 100);
      final unreadCount = alerts.where((alert) => !(alert['isRead'] as bool? ?? false)).length;
      
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = unreadCount;
        });
      }
    } catch (e) {
      print('Erro ao carregar contagem de notificações: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
    final user = appState.user;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                // Foto e nome do usuário (clicável para abrir sidebar)
                GestureDetector(
                  onTap: () {
                    drawerProvider.openProfileDrawer();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: user?.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.photoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  user?.name[0].toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${user?.name.split(' ').first ?? 'Piloto'} 👋',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            user?.pilotProfile ?? 'Piloto',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Botão de notificações
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const NotificationsSidebar(),
                        );
                        // Recarregar contagem após fechar o modal
                        _loadNotificationsCount();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.bell,
                          color: theme.iconTheme.color,
                          size: 22,
                        ),
                      ),
                    ),
                    // Badge de notificação (só mostra se houver notificações não lidas)
                    if (_unreadNotificationsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: _unreadNotificationsCount > 99 ? 24 : 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.alertRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _unreadNotificationsCount > 99 ? '99+' : '$_unreadNotificationsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (widget.title.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.showBackButton)
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: widget.onBackPressed ?? () => Navigator.of(context).pop(),
                      color: theme.iconTheme.color,
                    ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
