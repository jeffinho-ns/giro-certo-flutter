import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/social_feed_provider.dart';
import '../../services/social_service.dart';
import '../../models/post.dart';
import '../../widgets/social/post_card.dart';
import '../../widgets/social/feed_skeleton.dart';
import 'post_comments_sheet.dart';
import 'profile_page.dart';

/// Tela Explorar: feed com ordenação (recente / popular).
class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final feed = Provider.of<SocialFeedProvider>(context, listen: false);
    await feed.loadData(
      userBikeModel: appState.bike?.model,
      currentUserId: appState.user?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feed = Provider.of<SocialFeedProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          title: const Text('Explorar'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            PopupMenuButton<FeedOrder>(
              icon: const Icon(Icons.sort),
              tooltip: 'Ordenar',
              onSelected: (order) => feed.setFeedOrder(order),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: FeedOrder.recent,
                  child: Text('Mais recentes'),
                ),
                const PopupMenuItem(
                  value: FeedOrder.popular,
                  child: Text('Mais populares'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: feed.loading
            ? const FeedSkeleton()
            : feed.filteredPosts.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma publicação.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: feed.filteredPosts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final post = feed.filteredPosts[index];
                      return SocialPostCard(
                        post: post,
                        likeCount: feed.getLikeCount(post),
                        isLiked: feed.isPostLiked(post),
                        onLike: () => feed.toggleLike(post),
                        onComments: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => PostCommentsSheet(post: post),
                        ),
                        onOptions: () => _showOptions(context, post, feed),
                      );
                    },
                  ),
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    Post post,
    SocialFeedProvider feed,
  ) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isOwn = appState.user?.id == post.userId;

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
              leading: const Icon(Icons.person_outline),
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
              leading: const Icon(Icons.copy),
              title: const Text('Copiar texto'),
              onTap: () => Navigator.pop(context),
            ),
            if (isOwn)
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),
                onTap: () => Navigator.pop(context),
              )
            else
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Reportar'),
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    );
  }
}
