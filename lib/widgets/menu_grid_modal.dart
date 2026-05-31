import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_navigator_key.dart';
import '../providers/app_state_provider.dart';
import '../providers/drawer_provider.dart';
import '../utils/colors.dart';
import '../screens/maintenance/maintenance_detail_screen.dart';
import '../screens/partners/partners_screen.dart';
import '../screens/delivery/delivery_screen.dart';
import '../screens/social/user_search_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/social/create_post_modal.dart';
import '../screens/social/create_action_sheet.dart';
import '../screens/social/create_community_modal.dart';
import '../screens/social/send_notification_sheet.dart';
import '../screens/help/help_screen.dart';
import '../screens/momentos/momentos_screen.dart';
import '../screens/rotas/rotas_screen.dart';
import '../screens/ranking/ranking_screen.dart';
import '../screens/manual/manual_screen.dart';
import '../screens/social/events_screen.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/drive/drive_mode_screen.dart';
import '../screens/communities/communities_list_screen.dart';
import '../screens/delivery/delivery_history_screen.dart';
import '../screens/social/social_home_screen.dart';

class MenuGridModal extends StatefulWidget {
  final VoidCallback? onClose;
  final Function(int)? onNavigateToIndex;
  final bool isDeliveryPilot;
  final bool isPartner;

  const MenuGridModal({
    super.key,
    this.onClose,
    this.onNavigateToIndex,
    this.isDeliveryPilot = false,
    this.isPartner = false,
  });

  @override
  State<MenuGridModal> createState() => _MenuGridModalState();
}

class _MenuGridModalState extends State<MenuGridModal> {
  static const _usageKeyPrefix = 'menu_grid_usage_v2';
  Map<String, int> _usageById = const {};

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userId = appState.user?.id ?? 'anon';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_usageKeyPrefix:$userId') ?? const [];
    final map = <String, int>{};
    for (final item in raw) {
      final parts = item.split(':');
      if (parts.length != 2) continue;
      map[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
    if (!mounted) return;
    setState(() => _usageById = map);
  }

  Future<void> _markUsed(String id) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userId = appState.user?.id ?? 'anon';
    final next = Map<String, int>.from(_usageById);
    next[id] = (next[id] ?? 0) + 1;
    setState(() => _usageById = next);

    final prefs = await SharedPreferences.getInstance();
    final encoded = next.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList('$_usageKeyPrefix:$userId', encoded);
  }

  bool get _isDelivery {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    return widget.isDeliveryPilot || appState.isDeliveryPilot;
  }

  bool get _isPartner {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    return widget.isPartner || appState.user?.isPartner == true;
  }

  List<MenuQuickAction> _quickActions() {
    if (_isPartner) {
      return const [
        MenuQuickAction(
          id: 'qa_new_order',
          label: 'Novo Pedido',
          icon: LucideIcons.plusCircle,
          routeIndex: 115,
          highlight: true,
        ),
        MenuQuickAction(
          id: 'qa_orders',
          label: 'Pedidos',
          icon: LucideIcons.package,
          routeIndex: 105,
        ),
        MenuQuickAction(
          id: 'qa_profile',
          label: 'Perfil',
          icon: LucideIcons.userCircle2,
          routeIndex: 108,
        ),
      ];
    }

    if (_isDelivery) {
      return const [
        MenuQuickAction(
          id: 'qa_rides',
          label: 'Entrar em Corridas',
          icon: LucideIcons.package,
          routeIndex: 105,
          highlight: true,
        ),
        MenuQuickAction(
          id: 'qa_history',
          label: 'Histórico',
          icon: LucideIcons.history,
          routeIndex: 117,
        ),
        MenuQuickAction(
          id: 'qa_messages',
          label: 'Mensagens',
          icon: LucideIcons.messageCircle,
          routeIndex: 110,
        ),
      ];
    }

    return const [
      MenuQuickAction(
        id: 'qa_publish',
        label: 'Publicar',
        icon: LucideIcons.edit2,
        routeIndex: 109,
        highlight: true,
      ),
      MenuQuickAction(
        id: 'qa_routes',
        label: 'Rotas',
        icon: LucideIcons.mapPin,
        routeIndex: 111,
      ),
      MenuQuickAction(
        id: 'qa_partners',
        label: 'Parceiros',
        icon: LucideIcons.store,
        routeIndex: 102,
      ),
    ];
  }

  List<MenuGridItem> _baseItems() {
    if (_isPartner) {
      return const [
        MenuGridItem(
            id: 'orders',
            icon: LucideIcons.package,
            label: 'Pedidos',
            routeIndex: 105,
            highlight: true),
        MenuGridItem(
            id: 'new_order',
            icon: LucideIcons.plusCircle,
            label: 'Novo Pedido',
            routeIndex: 115,
            highlight: true),
        MenuGridItem(
            id: 'events',
            icon: LucideIcons.calendarDays,
            label: 'Eventos',
            routeIndex: 116),
        MenuGridItem(
            id: 'help',
            icon: LucideIcons.helpCircle,
            label: 'Ajuda',
            routeIndex: 112),
        MenuGridItem(
            id: 'messages',
            icon: LucideIcons.messageCircle,
            label: 'Mensagens',
            routeIndex: 110),
        MenuGridItem(
            id: 'partners',
            icon: LucideIcons.store,
            label: 'Parceiros',
            routeIndex: 102),
        MenuGridItem(
            id: 'profile',
            icon: LucideIcons.userCircle2,
            label: 'Perfil',
            routeIndex: 108),
      ];
    }

    return [
      const MenuGridItem(
          id: 'maintenance',
          icon: LucideIcons.wrench,
          label: 'Manutenção',
          routeIndex: 101),
      const MenuGridItem(
          id: 'partners',
          icon: LucideIcons.store,
          label: 'Parceiros',
          routeIndex: 102),
      MenuGridItem(
        id: 'rides',
        icon: LucideIcons.package,
        label: 'Corridas',
        routeIndex: 105,
        highlight: _isDelivery,
        enabled: _isDelivery,
        badgeText: _isDelivery ? null : 'Delivery',
      ),
      if (_isDelivery)
        const MenuGridItem(
            id: 'delivery_history',
            icon: LucideIcons.history,
            label: 'Histórico',
            routeIndex: 117),
      const MenuGridItem(
          id: 'routes',
          icon: LucideIcons.mapPin,
          label: 'Rotas',
          routeIndex: 111),
      const MenuGridItem(
          id: 'moments',
          icon: LucideIcons.sparkles,
          label: 'Momentos',
          routeIndex: 114),
      const MenuGridItem(
          id: 'communities',
          icon: LucideIcons.users,
          label: 'Comunidades',
          routeIndex: 118),
      const MenuGridItem(
          id: 'events',
          icon: LucideIcons.calendarDays,
          label: 'Eventos',
          routeIndex: 116),
      const MenuGridItem(
          id: 'news',
          icon: LucideIcons.newspaper,
          label: 'News',
          routeIndex: 121),
      const MenuGridItem(
          id: 'ranking',
          icon: LucideIcons.trophy,
          label: 'Ranking',
          routeIndex: 106),
      const MenuGridItem(
          id: 'achievements',
          icon: LucideIcons.award,
          label: 'Conquistas',
          routeIndex: 119),
      const MenuGridItem(
          id: 'manual',
          icon: LucideIcons.bookOpen,
          label: 'Manual',
          routeIndex: 120),
      const MenuGridItem(
          id: 'drive',
          icon: LucideIcons.car,
          label: 'Modo Drive',
          routeIndex: 113),
      const MenuGridItem(
          id: 'vehicles',
          icon: LucideIcons.bike,
          label: 'Garagem',
          routeIndex: 4),
      const MenuGridItem(
          id: 'search',
          icon: LucideIcons.search,
          label: 'Pesquisa',
          routeIndex: 107),
      const MenuGridItem(
          id: 'publish',
          icon: LucideIcons.edit2,
          label: 'Publicar',
          routeIndex: 109),
      const MenuGridItem(
          id: 'messages',
          icon: LucideIcons.messageCircle,
          label: 'Mensagens',
          routeIndex: 110),
      const MenuGridItem(
          id: 'help',
          icon: LucideIcons.helpCircle,
          label: 'Ajuda',
          routeIndex: 112),
      const MenuGridItem(
          id: 'profile',
          icon: LucideIcons.userCircle2,
          label: 'Perfil',
          routeIndex: 108),
    ];
  }

  List<MenuGridItem> _sortedByUsage(List<MenuGridItem> items) {
    final pinnedIds = {
      'maintenance',
      'partners',
      _isPartner ? 'orders' : 'rides'
    };
    final pinned = <MenuGridItem>[];
    final adaptive = <MenuGridItem>[];

    for (final item in items) {
      if (pinnedIds.contains(item.id)) {
        pinned.add(item);
      } else {
        adaptive.add(item);
      }
    }

    adaptive.sort((a, b) {
      final aCount = _usageById[a.id] ?? 0;
      final bCount = _usageById[b.id] ?? 0;
      if (aCount != bCount) return bCount.compareTo(aCount);
      return a.label.compareTo(b.label);
    });

    return [...pinned, ...adaptive];
  }

  Future<void> _handleRouteTap(MenuGridItem item) async {
    if (!item.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corridas disponível apenas para perfil Delivery.'),
        ),
      );
      return;
    }

    await _markUsed(item.id);
    widget.onClose?.call();

    if (item.routeIndex == 109) {
      final rootContext = appNavigatorKey.currentContext;
      if (!mounted) return;
      Navigator.of(context).pop();
      if (rootContext != null) {
        await _openCreateActionModal(rootContext);
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    if (item.routeIndex >= 0 &&
        item.routeIndex <= 4 &&
        widget.onNavigateToIndex != null) {
      widget.onNavigateToIndex!(item.routeIndex);
      return;
    }

    switch (item.routeIndex) {
      case 101:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MaintenanceDetailScreen()),
        );
        break;
      case 102:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PartnersScreen()),
        );
        break;
      case 105:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DeliveryScreen()),
        );
        break;
      case 109:
        break;
      case 107:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UserSearchScreen()),
        );
        break;
      case 108:
        Provider.of<DrawerProvider>(context, listen: false).openProfileDrawer();
        break;
      case 110:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
        break;
      case 106:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RankingScreen()),
        );
        break;
      case 111:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RotasScreen()),
        );
        break;
      case 112:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HelpScreen()),
        );
        break;
      case 113:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DriveModeScreen()),
        );
        break;
      case 114:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MomentosScreen()),
        );
        break;
      case 115:
        // Novo pedido (lojista): vai para DeliveryScreen com flag para abrir o
        // CreateDeliveryModal automaticamente.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DeliveryScreen(autoOpenCreate: true),
          ),
        );
        break;
      case 116:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EventsScreen()),
        );
        break;
      case 117:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
        );
        break;
      case 118:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CommunitiesListScreen()),
        );
        break;
      case 119:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
        );
        break;
      case 120:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManualScreen()),
        );
        break;
      case 121:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SocialHomeScreen(fromMenu: true),
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _openCreateActionModal(BuildContext presentationContext) async {
    final appState = Provider.of<AppStateProvider>(
      presentationContext,
      listen: false,
    );
    final user = appState.user;
    if (user == null) return;

    final action = await CreateActionSheet.show(presentationContext);
    if (action == null) return;

    switch (action) {
      case CreateActionType.post:
        final bikeModel = appState.bike?.model ?? 'Moto';
        final post = await showModalBottomSheet<dynamic>(
          context: presentationContext,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CreatePostModal(
            user: user,
            userBikeModel: bikeModel,
          ),
        );
        if (post != null) {
          ScaffoldMessenger.of(presentationContext).showSnackBar(
            const SnackBar(content: Text('Publicação enviada com sucesso!')),
          );
        }
        break;
      case CreateActionType.community:
        final community = await showModalBottomSheet<dynamic>(
          context: presentationContext,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CreateCommunityModal(),
        );
        if (community != null) {
          ScaffoldMessenger.of(presentationContext).showSnackBar(
            const SnackBar(content: Text('Comunidade criada com sucesso!')),
          );
        }
        break;
      case CreateActionType.notification:
        await SendNotificationSheet.show(presentationContext);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = _sortedByUsage(_baseItems());
    final quickActions = _quickActions();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
            isDark ? AppColors.panelDarkLow : AppColors.panelLightLow,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.racingOrange.withOpacity(0.16)),
        boxShadow: AppColors.raisedPanelShadows(isDark),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onClose?.call();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
              child: _QuickActionsRow(
                actions: quickActions,
                onTap: (a) => _handleRouteTap(
                  MenuGridItem(
                    id: a.id,
                    icon: a.icon,
                    label: a.label,
                    routeIndex: a.routeIndex,
                    highlight: a.highlight,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: items
                      .map(
                        (item) => _GridTile(
                          item: item,
                          theme: theme,
                          onTap: () => _handleRouteTap(item),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuQuickAction {
  final String id;
  final String label;
  final IconData icon;
  final int routeIndex;
  final bool highlight;

  const MenuQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.routeIndex,
    this.highlight = false,
  });
}

class _QuickActionsRow extends StatelessWidget {
  final List<MenuQuickAction> actions;
  final ValueChanged<MenuQuickAction> onTap;

  const _QuickActionsRow({
    required this.actions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onTap(a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: a.highlight
                              ? [
                                  AppColors.racingOrangeLight.withOpacity(0.92),
                                  AppColors.racingOrangeDark.withOpacity(0.9),
                                ]
                              : [
                                  theme.brightness == Brightness.dark
                                      ? AppColors.panelDarkHigh
                                      : AppColors.panelLightHigh,
                                  theme.brightness == Brightness.dark
                                      ? AppColors.panelDarkLow
                                      : AppColors.panelLightLow,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.16),
                        ),
                        boxShadow: AppColors.insetPanelShadows(
                            theme.brightness == Brightness.dark),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            a.icon,
                            size: 18,
                            color: a.highlight
                                ? Colors.white
                                : theme.colorScheme.primary.withOpacity(0.85),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: a.highlight ? Colors.white : null,
                              fontWeight: a.highlight
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class MenuGridItem {
  final String id;
  final IconData icon;
  final String label;
  final int routeIndex;
  final bool highlight;
  final bool enabled;
  final String? badgeText;

  const MenuGridItem({
    required this.id,
    required this.icon,
    required this.label,
    this.routeIndex = -1,
    this.highlight = false,
    this.enabled = true,
    this.badgeText,
  });
}

class _GridTile extends StatelessWidget {
  final MenuGridItem item;
  final ThemeData theme;
  final VoidCallback onTap;

  const _GridTile({
    required this.item,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlight = item.highlight;
    final isEnabled = item.enabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHighlight
                  ? [
                      AppColors.racingOrangeLight.withOpacity(0.9),
                      AppColors.racingOrangeDark.withOpacity(0.88),
                    ]
                  : [
                      theme.brightness == Brightness.dark
                          ? AppColors.panelDarkHigh
                          : AppColors.panelLightHigh,
                      theme.brightness == Brightness.dark
                          ? AppColors.panelDarkLow
                          : AppColors.panelLightLow,
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHighlight
                  ? Colors.white.withOpacity(0.2)
                  : theme.dividerColor.withOpacity(isEnabled ? 0.6 : 0.35),
              width: 1,
            ),
            boxShadow: AppColors.raisedPanelShadows(
                theme.brightness == Brightness.dark),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? Colors.white.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: isHighlight
                      ? Colors.white
                      : theme.colorScheme.primary
                          .withOpacity(isEnabled ? 0.8 : 0.45),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
                  color: isHighlight
                      ? Colors.white
                      : theme.textTheme.bodySmall?.color?.withOpacity(
                          isEnabled ? 0.85 : 0.45,
                        ),
                ),
              ),
              if (item.badgeText != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.badgeText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
