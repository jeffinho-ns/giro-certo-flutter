import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/colors.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/social_feed_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/social/post_card.dart';
import '../../services/social_service.dart';
import '../chat/chat_screen.dart';
import 'story_view_screen.dart';
import 'post_comments_sheet.dart';
import 'follow_list_screen.dart';
import '../../widgets/api_image.dart';

/// Perfil público de outro utilizador com posts, stories, Seguir e Mensagem.
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String? userBikeModel;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.userBikeModel,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final feed = Provider.of<SocialFeedProvider>(context, listen: false);
    await feed.loadProfileData(
      widget.userId,
      currentUserId: appState.user?.id,
    );
  }

  Future<void> _openChat() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final currentUser = appState.user;
    if (currentUser == null) return;
    final conv = await ChatService.getOrCreatePrivateChat(
      currentUserId: currentUser.id,
      recipientId: widget.userId,
      recipientName: widget.userName,
      recipientPhotoUrl: widget.userAvatarUrl,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialConversation: conv),
      ),
    );
  }

  void _openComments(dynamic post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCommentsSheet(post: post),
    );
  }

  Widget _buildCountChip(BuildContext context, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Widget _defaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D2642),
            Color(0xFF454060),
            Color(0xFF3A3550),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final feed = Provider.of<SocialFeedProvider>(context);
    final isOwnProfile = appState.user?.id == widget.userId;
    final profilePosts = feed.getProfilePosts(widget.userId);
    final profileStories = feed.getProfileStories(widget.userId);
    final profileUser = feed.getProfileUserData(widget.userId);
    final isLoading = feed.isProfileLoading(widget.userId);
    final isFollowing = feed.isFollowing(widget.userId);

    final avatarUrl = profileUser?['photoUrl'] as String? ??
        widget.userAvatarUrl;
    final coverUrl = profileUser?['coverUrl'] as String?;
    final followersCount = (profileUser?['followersCount'] as num?)?.toInt() ?? 0;
    final followingCount = (profileUser?['followingCount'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (coverUrl != null && coverUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 3,
                  child: ApiImage(
                    url: coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultCover(),
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 3,
                  child: _defaultCover(),
                ),
              Transform.translate(
                offset: const Offset(0, -44),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.racingOrange.withOpacity(0.2),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: SizedBox(
                              width: 92,
                              height: 92,
                              child: ApiImage(url: avatarUrl, fit: BoxFit.cover),
                            ),
                          )
                        : Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.racingOrange,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.userName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.userBikeModel != null &&
                  widget.userBikeModel!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.userBikeModel!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCountChip(
                    context,
                    '$followersCount Seguidores',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FollowListScreen(
                          userId: widget.userId,
                          title: 'Seguidores',
                          isFollowers: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildCountChip(
                    context,
                    '$followingCount A seguir',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FollowListScreen(
                          userId: widget.userId,
                          title: 'A seguir',
                          isFollowers: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!isOwnProfile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final currentUserId =
                                      appState.user?.id ?? '';
                                  if (currentUserId.isEmpty) return;
                                  await feed.toggleFollow(
                                    currentUserId,
                                    widget.userId,
                                  );
                                },
                          icon: Icon(
                            isFollowing ? LucideIcons.userMinus : LucideIcons.userPlus,
                            size: 18,
                          ),
                          label: Text(isFollowing ? 'Deixar de seguir' : 'Seguir'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.racingOrange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _openChat,
                        icon: const Icon(LucideIcons.messageCircle, size: 18),
                        label: const Text('Mensagem'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.racingOrange.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isOwnProfile) const SizedBox(height: 24),
              if (profileStories.isNotEmpty) ...[
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: profileStories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final s = profileStories[i];
                      final isAsset = s.mediaUrl.startsWith('assets/');
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StoryViewScreen(
                                stories: profileStories,
                                initialIndex: i,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.racingOrange,
                                  width: 2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: isAsset
                                  ? Image.asset(s.mediaUrl, fit: BoxFit.cover)
                                  : ApiImage(
                                      url: s.mediaUrl,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 72,
                              child: Text(
                                s.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Momentos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (profilePosts.isEmpty)
                _EmptyState(
                  icon: LucideIcons.sparkles,
                  title: 'Este piloto ainda não postou momentos',
                  subtitle:
                      'Quando publicar, os momentos aparecerão aqui.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: profilePosts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final post = profilePosts[i];
                    return SocialPostCard(
                      post: post,
                      likeCount: SocialService.getPostLikeCount(post),
                      isLiked: SocialService.isPostLiked(post.id),
                      onLike: () async {
                        await SocialService.togglePostLike(
                          post.id,
                          currentLikeCount: post.likes,
                        );
                        if (mounted) setState(() {});
                      },
                      onComments: () => _openComments(post),
                      onOptions: () {},
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.racingOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.racingOrange.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
