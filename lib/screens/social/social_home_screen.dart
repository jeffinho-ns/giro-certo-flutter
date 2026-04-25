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
import 'story_view_screen.dart';
import 'story_preview_edit_screen.dart';
import 'create_story_sheet.dart';
import 'post_comments_sheet.dart';
import 'report_post_sheet.dart';
import 'notifications_screen.dart';
import 'profile_page.dart';
import 'user_profile_screen.dart';
import 'user_search_screen.dart';
import '../ranking/ranking_screen.dart';
import '../momentos/momentos_screen.dart';
import '../garage/garage_screen.dart';
import '../chat/chat_screen.dart';

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
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
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
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final feed = Provider.of<SocialFeedProvider>(context, listen: false);
    await feed.loadData(
      userBikeModel: appState.bike?.model,
      currentUserId: appState.user?.id,
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
                        : UserProfileScreen(
                            userId: post.userId,
                            userName: post.userName,
                            userAvatarUrl: post.userAvatarUrl,
                            userBikeModel: post.userBikeModel,
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
        MaterialPageRoute(builder: (_) => const RankingScreen()),
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
                MaterialPageRoute(builder: (_) => const RankingScreen()),
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
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
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
                            builder: (_) => const UserSearchScreen(),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.users),
                      tooltip: 'Procurar utilizadores @',
                    ),
                  ],
                ),
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
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
