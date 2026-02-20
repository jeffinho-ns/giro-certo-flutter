import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/social_feed_provider.dart';
import '../sidebars/profile_sidebar.dart';
import '../../widgets/modern_header.dart';
import '../../services/social_service.dart';
import '../../models/post.dart';
import '../../widgets/social/social_search_bar.dart';
import '../../widgets/social/story_tile.dart';
import '../../widgets/social/post_card.dart';
import '../../widgets/social/social_bottom_nav.dart';
import '../../widgets/social/feed_skeleton.dart';
import 'story_view_screen.dart';
import 'create_post_modal.dart';
import 'create_story_sheet.dart';
import 'create_action_sheet.dart';
import 'create_community_modal.dart';
import 'send_notification_sheet.dart';
import 'post_comments_sheet.dart';
import 'report_post_sheet.dart';
import 'notifications_screen.dart';
import 'explorar_screen.dart';
import 'profile_page.dart';
import 'user_search_screen.dart';
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
                    builder: (_) => ProfilePage(
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

  void _openCreatePost() async {
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    final bike = Provider.of<AppStateProvider>(context, listen: false).bike;
    final feed = Provider.of<SocialFeedProvider>(context, listen: false);
    if (user == null) return;
    final post = await showModalBottomSheet<Post>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostModal(
        user: user,
        userBikeModel: bike?.model ?? 'Moto',
      ),
    );
    if (post != null) {
      feed.prependPost(post);
    }
  }

  void _openCreateAction() async {
    final action = await CreateActionSheet.show(context);
    if (action == null || !mounted) return;
    switch (action) {
      case CreateActionType.post:
        _openCreatePost();
        break;
      case CreateActionType.community:
        final community = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const CreateCommunityModal(),
        );
        if (community != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comunidade criada com sucesso!')),
          );
        }
        break;
      case CreateActionType.notification:
        await SendNotificationSheet.show(context);
        break;
    }
  }

  Future<void> _openCreateStory() async {
    final created = await CreateStorySheet.show(context);
    if (created == true) _loadData();
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _openCreateAction();
      return;
    }
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    }
    if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfilePage(),
        ),
      );
      return;
    }
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExplorarScreen()),
      );
      return;
    }
    setState(() => _currentNavIndex = index);
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
                child: IconButton(
                  icon: const Icon(LucideIcons.bell),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => StoryViewScreen(
                                      stories: feed.stories,
                                      initialIndex: index - 1,
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
                      );
                    },
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SocialBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
