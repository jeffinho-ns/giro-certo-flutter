import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/social_feed_provider.dart';
import '../../providers/notifications_count_provider.dart';
import '../sidebars/profile_sidebar.dart';
import '../../widgets/modern_header.dart';
import '../../services/social_service.dart';
import '../../models/post.dart';
import '../../models/reaction_type.dart';
import '../../services/api_service.dart';
import '../../widgets/social/social_search_bar.dart';
import '../../widgets/social/story_tile.dart';
import '../../widgets/social/post_card.dart';
import '../../widgets/floating_bottom_nav.dart';
import '../../widgets/menu_grid_modal.dart';
import '../../widgets/social/feed_skeleton.dart';
import '../../utils/colors.dart';
import 'story_view_screen.dart';
import 'story_preview_edit_screen.dart';
import 'create_story_sheet.dart';
import 'create_post_modal.dart';
import 'post_comments_sheet.dart';
import 'report_post_sheet.dart';
import 'notifications_screen.dart';
import 'profile_page.dart';
import 'user_search_screen.dart';
import 'explorar_screen.dart';
import 'events_screen.dart';
import '../momentos/momentos_screen.dart';
import '../garage/garage_screen.dart';
import '../chat/chat_screen.dart';
import '../maintenance/maintenance_detail_screen.dart';
import '../../models/user.dart';
import '../../models/community_type.dart';
import '../../services/maintenance_service.dart';
import '../../widgets/critical_alert_card.dart';
import '../communities/communities_list_screen.dart';

class SocialHomeScreen extends StatefulWidget {
  /// Quando true, a tela foi aberta pelo menu (ex.: News); mostra botão para voltar à home padrão.
  final bool fromMenu;

  const SocialHomeScreen({super.key, this.fromMenu = false});

  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentNavIndex = 0;
  int _nearbyEventsCount = 0;
  bool _didApplyInitialFeedDefaults = false;
  MaintenanceSummary? _maintenanceSummary;
  String? _maintenanceHighlight;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final countProvider = Provider.of<NotificationsCountProvider>(context, listen: false);
      countProvider.loadFromApi();
      countProvider.subscribeToRealtime();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawerProvider =
          Provider.of<DrawerProvider>(context, listen: false);
      drawerProvider.setScaffoldKey(_scaffoldKey);
      _loadData();
      _loadNearbyEventHint();
      _loadMaintenanceAlert();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final feed = Provider.of<SocialFeedProvider>(context, listen: false);
    final threshold = _scrollController.position.maxScrollExtent - 280;
    if (_scrollController.position.pixels >= threshold) {
      feed.loadMorePosts();
    }
  }

  Future<void> _loadData() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final feed = Provider.of<SocialFeedProvider>(context, listen: false);
    if (!_didApplyInitialFeedDefaults) {
      feed.setFeedTab(FeedTab.forYou);
      feed.setPilotFilter(FeedPilotFilter.all);
      feed.setHashtagFilter('');
      _didApplyInitialFeedDefaults = true;
    }
    await feed.loadData(
      userBikeModel: appState.bike?.model,
      currentUserId: appState.user?.id,
    );
    await _loadMaintenanceAlert();
  }

  Future<void> _loadMaintenanceAlert() async {
    final bike =
        Provider.of<AppStateProvider>(context, listen: false).bike;
    if (bike == null) {
      if (!mounted) return;
      setState(() {
        _maintenanceSummary = null;
        _maintenanceHighlight = null;
      });
      return;
    }
    try {
      final items = await MaintenanceService.loadMaintenances(bike);
      if (!mounted) return;
      final summary = MaintenanceService.buildSummary(items);
      if (!summary.hasCritical && !summary.hasWarning) {
        setState(() {
          _maintenanceSummary = null;
          _maintenanceHighlight = null;
        });
        return;
      }
      final alertItems = items
          .where((m) => m.status == 'Crítico' || m.status == 'Atenção')
          .toList()
        ..sort((a, b) => b.wearPercentage.compareTo(a.wearPercentage));
      final top = alertItems.isNotEmpty ? alertItems.first : null;
      final remaining = top == null
          ? null
          : (top.remainingKm <= 0
              ? 'troca recomendada agora'
              : '${top.remainingKm} km restantes');
      setState(() {
        _maintenanceSummary = summary;
        _maintenanceHighlight = top == null
            ? null
            : '${top.partName} · $remaining';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _maintenanceSummary = null;
        _maintenanceHighlight = null;
      });
    }
  }

  void _openMaintenanceDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MaintenanceDetailScreen()),
    ).then((_) => _loadMaintenanceAlert());
  }

  Widget _buildMaintenanceAlertBanner(ThemeData theme) {
    final summary = _maintenanceSummary;
    if (summary == null || (!summary.hasCritical && !summary.hasWarning)) {
      return const SizedBox.shrink();
    }
    final isCritical = summary.hasCritical;
    final title = isCritical
        ? 'Manutenção crítica na sua moto'
        : 'Manutenção precisa de atenção';
    final message = _maintenanceHighlight ??
        (isCritical
            ? '${summary.criticalCount} item(ns) crítico(s). Toque para ver.'
            : '${summary.warningCount} item(ns) em atenção. Toque para ver.');

    if (isCritical) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CriticalAlertCard(
          title: title,
          message: message,
          onTap: _openMaintenanceDetail,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openMaintenanceDetail,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusWarning.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.statusWarning.withOpacity(0.55),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  color: AppColors.statusWarning,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.statusWarning,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.statusWarning,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadNearbyEventHint() async {
    final events = await ApiService.getEvents(limit: 1);
    if (!mounted) return;
    setState(() {
      _nearbyEventsCount = events.isEmpty ? 0 : 1;
    });
  }

  Widget _buildProfileDynamicCard(ThemeData theme, AppStateProvider appState) {
    final userType = parseUserType(appState.user?.pilotProfile);
    String title;
    String subtitle;
    IconData icon;
    VoidCallback action;
    switch (userType) {
      case UserType.casual:
        title = 'Seu fim de semana começa aqui';
        subtitle = 'Explore eventos e rotas bonitas para seu próximo rolê.';
        icon = LucideIcons.mountain;
        action = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventsScreen()),
            );
        break;
      case UserType.diario:
        title = 'Rotina mais inteligente';
        subtitle = 'Confira dicas urbanas e mantenha sua moto em dia.';
        icon = LucideIcons.mapPin;
        action = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GarageScreen()),
            );
        break;
      case UserType.racing:
        title = 'Modo performance';
        subtitle = 'Compartilhe setup e veja novidades de pista.';
        icon = LucideIcons.flag;
        action = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExplorarScreen()),
            );
        break;
      case UserType.delivery:
        title = 'Comunidade de entregadores';
        subtitle = 'Troque rota, segurança e estratégia com outros riders.';
        icon = LucideIcons.packageSearch;
        action = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunitiesListScreen(
                  initialType: CommunityType.delivery,
                ),
              ),
            );
        break;
      default:
        title = 'Conecte-se com a comunidade';
        subtitle = 'Veja dicas, eventos e pilotos perto de você.';
        icon = LucideIcons.sparkles;
        action = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunitiesListScreen()),
            );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.racingOrange.withOpacity(0.14),
            ),
            child: Icon(icon, color: AppColors.racingOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: action, child: const Text('Abrir')),
        ],
      ),
    );
  }

  Widget _buildCommunityAndEventsShortcuts(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildShortcutTile(
            theme,
            icon: LucideIcons.users,
            label: 'Comunidades',
            subtitle: 'Grupos e chats',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunitiesListScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildShortcutTile(
            theme,
            icon: LucideIcons.calendar,
            label: 'Eventos',
            subtitle: _nearbyEventsCount > 0 ? 'Há eventos perto' : 'Rolês e encontros',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: theme.cardColor,
            border: Border.all(
              color: AppColors.racingOrange.withOpacity(0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.racingOrange.withOpacity(0.14),
                ),
                child: Icon(icon, color: AppColors.racingOrange, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedCommunityCard(ThemeData theme, AppStateProvider appState) {
    final userType = parseUserType(appState.user?.pilotProfile);
    final suggestedTypes = switch (userType) {
      UserType.casual => [CommunityType.lazer, CommunityType.zona],
      UserType.diario => [CommunityType.zona, CommunityType.manutencao],
      UserType.racing => [CommunityType.marca, CommunityType.lazer],
      UserType.delivery => [CommunityType.delivery, CommunityType.zona],
      _ => [CommunityType.geral, CommunityType.zona],
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comunidades recomendadas para seu perfil',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunitiesListScreen()),
                ),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestedTypes
                .map(
                  (t) => ActionChip(
                    label: Text(t.label),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunitiesListScreen(initialType: t),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreatePost() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final feed = Provider.of<SocialFeedProvider>(context, listen: false);
    final user = appState.user;
    if (user == null) return;
    final post = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostModal(
        user: user,
        userBikeModel: appState.bike?.model ?? 'Moto',
      ),
    );
    if (!mounted || post == null) return;
    if (post is Post) {
      feed.prependPost(post);
    } else {
      await _loadData();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publicação enviada com sucesso!')),
    );
  }

  void _openComments(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCommentsSheet(post: post),
    );
  }

  void _showPostOptions(Post post) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final feed = Provider.of<SocialFeedProvider>(context, listen: false);
    final isOwnPost = appState.user?.id == post.userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.user),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => isOwnPost
                        ? const ProfilePage()
                        : ProfilePage(
                            userId: post.userId,
                            userName: post.userName,
                          ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.copy),
              title: const Text('Copiar texto'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: post.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texto copiado')),
                );
              },
            ),
            if (isOwnPost) ...[
              ListTile(
                leading: const Icon(LucideIcons.edit),
                title: const Text('Editar'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(LucideIcons.trash2, color: theme.colorScheme.error),
                title: Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await SocialService.deletePost(post.id, post.userId);
                  if (ok && mounted) feed.removePost(post.id);
                },
              ),
            ] else
              ListTile(
                leading: const Icon(LucideIcons.flag),
                title: const Text('Reportar'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ReportPostSheet(postId: post.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateStory() async {
    final result = await CreateStorySheet.show(context);
    if (!mounted) return;
    if (result is Map && result['openPreview'] == true) {
      await StoryPreviewEditScreen.push(
        context,
        imagePath: result['imagePath'] as String,
        userId: result['userId'] as String,
        userName: result['userName'] as String,
        userAvatarUrl: result['userAvatarUrl'] as String?,
      );
      // A story já foi adicionada ao feed no ecrã de preview; não chamar prependStory aqui para não duplicar
    } else if (result == true) {
      _loadData();
    }
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _openUnifiedMenu();
      return;
    }
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MomentosScreen()),
      );
      return;
    }
    if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GarageScreen()),
      );
      return;
    }
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EventsScreen()),
      );
      return;
    }
    if (index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    }
    setState(() => _currentNavIndex = index);
  }

  void _openUnifiedMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        return MenuGridModal(
          onClose: () {},
          isDeliveryPilot: appState.isDeliveryPilot,
          isPartner: appState.user?.isPartner ?? false,
          onNavigateToIndex: (routeIndex) {
            if (routeIndex == 0) {
              setState(() => _currentNavIndex = 0);
              return;
            }
            if (routeIndex == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EventsScreen()),
              );
              return;
            }
            if (routeIndex == 2) {
              return;
            }
            if (routeIndex == 3) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MomentosScreen()),
              );
              return;
            }
            if (routeIndex == 4) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GarageScreen()),
              );
              return;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feed = Provider.of<SocialFeedProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Stack(
          children: [
            ModernHeader(
              title: '',
              transparentOverMap: false,
              hideClockAndKm: true,
            ),
            if (widget.fromMenu)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Voltar para a home',
                  ),
                ),
              ),
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Consumer<NotificationsCountProvider>(
                  builder: (context, countProvider, _) {
                    final count = countProvider.unreadCount;
                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text(count > 99 ? '99+' : '$count'),
                      child: IconButton(
                        icon: const Icon(LucideIcons.bell),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                          if (context.mounted) {
                            Provider.of<NotificationsCountProvider>(context, listen: false).loadFromApi();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      endDrawer: const ProfileSidebar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                _buildMaintenanceAlertBanner(theme),
                Row(
                  children: [
                    Expanded(
                      child: SocialSearchBar(
                        controller: _searchController,
                        hintText: 'Procurar publicações...',
                        onChanged: (v) => feed.setSearchQuery(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExplorarScreen(),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.compass),
                      tooltip: 'Explorar',
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserSearchScreen(),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.users),
                      tooltip: 'Procurar utilizadores @',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Para você'),
                              selected: feed.feedTab == FeedTab.forYou,
                              onSelected: (_) => feed.setFeedTab(FeedTab.forYou),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Seguindo'),
                              selected: feed.feedTab == FeedTab.following,
                              onSelected: (_) => feed.setFeedTab(FeedTab.following),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Todos'),
                              selected: feed.pilotFilter == FeedPilotFilter.all,
                              onSelected: (_) => feed.setPilotFilter(FeedPilotFilter.all),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Lazer'),
                              selected: feed.pilotFilter == FeedPilotFilter.lazer,
                              onSelected: (_) => feed.setPilotFilter(FeedPilotFilter.lazer),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Delivery'),
                              selected: feed.pilotFilter == FeedPilotFilter.delivery,
                              onSelected: (_) => feed.setPilotFilter(FeedPilotFilter.delivery),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<NotificationsCountProvider>(
                  builder: (context, countProvider, _) {
                    final unread = countProvider.unreadCount;
                    final hasEvent = _nearbyEventsCount > 0;
                    if (unread == 0 && !hasEvent) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: theme.colorScheme.primaryContainer.withOpacity(0.32),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.sparkles, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Você tem $unread notificações não lidas${hasEvent ? ' e ${_nearbyEventsCount} evento perto' : ''}.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => unread > 0
                                      ? const NotificationsScreen()
                                      : const EventsScreen(),
                                ),
                              );
                            },
                            child: Text(unread > 0 ? 'Ver agora' : 'Ver evento'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildProfileDynamicCard(theme, appState),
                const SizedBox(height: 10),
                _buildCommunityAndEventsShortcuts(theme),
                const SizedBox(height: 10),
                _buildSuggestedCommunityCard(theme, appState),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: feed.loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: feed.stories.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return StoryTile(
                                onAddTap: _openCreateStory,
                              );
                            }
                            final story = feed.stories[index - 1];
                            return StoryTile(
                              story: story,
                              storyIndex: index - 1,
                              allStories: feed.stories,
                              onStoryTap: () {
                                final appState = Provider.of<AppStateProvider>(context, listen: false);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => StoryViewScreen(
                                      stories: feed.stories,
                                      initialIndex: index - 1,
                                      currentUserId: appState.user?.id,
                                      onStoryDeleted: (id) => feed.removeStory(id),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
                if (feed.loading)
                  const FeedSkeleton()
                else if (feed.filteredPosts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        feed.searchQuery.isNotEmpty
                            ? 'Nenhum resultado para "${feed.searchQuery}"'
                            : 'Nenhuma publicação ainda.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: feed.filteredPosts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final post = feed.filteredPosts[index];
                      return SocialPostCard(
                        post: post,
                        likeCount: feed.getLikeCount(post),
                        isLiked: feed.isPostLiked(post),
                        onLike: () => feed.toggleLike(post),
                        onComments: () => _openComments(post),
                        onOptions: () => _showPostOptions(post),
                        onUserTap: () {
                          final appUser = Provider.of<AppStateProvider>(
                            context,
                            listen: false,
                          ).user;
                          final isOwn = appUser?.id == post.userId;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => isOwn
                                  ? const ProfilePage()
                                  : ProfilePage(
                                      userId: post.userId,
                                      userName: post.userName,
                                    ),
                            ),
                          );
                        },
                        onHashtagTap: (tag) {
                          feed.setHashtagFilter(tag);
                          _loadData();
                        },
                        onReaction: (type) async {
                          await ApiService.setPostReaction(
                            post.id,
                            type.apiValue,
                          );
                          if (context.mounted) _loadData();
                        },
                      );
                    },
                  ),
                if (feed.loadingMore)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                if (!feed.loadingMore && !feed.hasMorePosts && feed.filteredPosts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: Text(
                        'Você chegou ao fim do feed.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        backgroundColor: AppColors.racingOrange,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Publicar agora',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
