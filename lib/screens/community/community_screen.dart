import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/post.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/social_feed_provider.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/social/post_card.dart';
import '../social/post_comments_sheet.dart';

class CommunityScreen extends StatefulWidget {
  final bool embeddedInTabs;

  const CommunityScreen({super.key, this.embeddedInTabs = false});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const _engagementMetricsKey = 'community_engagement_metrics_v1';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final feed = Provider.of<SocialFeedProvider>(context, listen: false);
      await feed.loadData(
        userBikeModel: appState.bike?.model,
        currentUserId: appState.user?.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike;
    final theme = Theme.of(context);

    if (bike == null) {
      final empty = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.bike,
                size: 64,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text('Configure sua moto na garagem',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                'Para visualizar a comunidade, você precisa cadastrar uma moto.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      if (widget.embeddedInTabs) return empty;
      return SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Comunidade',
              showBackButton: true,
              onBackPressed: () =>
                  Provider.of<NavigationProvider>(context, listen: false)
                      .navigateTo(2),
            ),
            Expanded(child: empty),
          ],
        ),
      );
    }

    final feed = Provider.of<SocialFeedProvider>(context);
    final posts = feed.filteredPosts;

    Widget list = feed.loading
        ? const Center(child: CircularProgressIndicator())
        : posts.isEmpty
            ? Center(
                child: Text(
                  'Sem posts na comunidade por enquanto.',
                  style: theme.textTheme.bodyLarge,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SocialPostCard(
                      post: post,
                      likeCount: feed.getLikeCount(post),
                      isLiked: feed.isPostLiked(post),
                      onLike: () async {
                        await _trackEngagement('like_button');
                        await feed.toggleLike(post);
                      },
                      onComments: () async {
                        await _trackEngagement('comment_button');
                        _openComments(post);
                      },
                      onOptions: () async {
                        await _trackEngagement('options_button');
                        _showPostActions(post);
                      },
                    ),
                  );
                },
              );

    if (widget.embeddedInTabs) return list;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          ModernHeader(
            title: 'Comunidade',
            showBackButton: true,
            onBackPressed: () =>
                Provider.of<NavigationProvider>(context, listen: false)
                    .navigateTo(2),
          ),
          Expanded(child: list),
        ],
      ),
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

  void _showPostActions(Post post) {
    final theme = Theme.of(context);

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
              leading: const Icon(LucideIcons.heart),
              title: const Text('Curtir'),
              onTap: () async {
                await _trackEngagement('like_action');
                await Provider.of<SocialFeedProvider>(this.context,
                        listen: false)
                    .toggleLike(post);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.messageCircle),
              title: const Text('Comentar'),
              onTap: () async {
                await _trackEngagement('comment_action');
                Navigator.pop(context);
                _openComments(post);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.share2),
              title: const Text('Compartilhar'),
              onTap: () async {
                await _trackEngagement('share_action');
                Navigator.pop(context);
                _openShareSheet(post);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.copy),
              title: const Text('Copiar texto'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: post.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Texto copiado')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openShareSheet(Post post) {
    final theme = Theme.of(context);

    Future<void> openExternal(Uri uri) async {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await _trackEngagement('share_fallback_system');
        await SharePlus.instance.share(
          ShareParams(
            text: _shareMessage(post),
            subject: 'Giro Certo • Comunidade',
          ),
        );
      }
    }

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
              leading: const CircleAvatar(
                radius: 14,
                child: Icon(LucideIcons.rss, size: 14),
              ),
              title: const Text('Compartilhar no seu feed'),
              onTap: () async {
                await _trackEngagement('share_feed');
                Navigator.pop(context);
                _shareToMyFeed(post);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 14,
                child: Text(
                  'WA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              title: const Text('WhatsApp'),
              onTap: () async {
                await _trackEngagement('share_whatsapp');
                Navigator.pop(context);
                openExternal(Uri.parse(
                    'https://wa.me/?text=${Uri.encodeComponent(_shareMessageForChannel(post, "whatsapp"))}'));
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 14,
                child: Text(
                  'IG',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              title: const Text('Instagram'),
              onTap: () async {
                await _trackEngagement('share_instagram');
                Navigator.pop(context);
                await SharePlus.instance.share(
                  ShareParams(
                    text: _shareMessageForChannel(post, 'instagram'),
                    subject: 'Giro Certo • Comunidade',
                  ),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 14,
                child: Text(
                  'MSG',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              title: const Text('Messages'),
              onTap: () async {
                await _trackEngagement('share_messages');
                Navigator.pop(context);
                openExternal(Uri.parse(
                    'sms:?body=${Uri.encodeComponent(_shareMessageForChannel(post, "messages"))}'));
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 14,
                child: Text(
                  'SC',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              title: const Text('Snapchat'),
              onTap: () async {
                await _trackEngagement('share_snapchat');
                Navigator.pop(context);
                await SharePlus.instance.share(
                  ShareParams(
                    text: _shareMessageForChannel(post, 'snapchat'),
                    subject: 'Giro Certo • Comunidade',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareToMyFeed(Post post) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final me = appState.user;
    if (me == null) return;

    final newPost = Post(
      id: 'share_${DateTime.now().millisecondsSinceEpoch}',
      userId: me.id,
      userName: me.name,
      userBikeModel: appState.bike?.model ?? 'Moto',
      userAvatarUrl: me.photoUrl,
      userPilotProfile: me.pilotProfile,
      content: 'Repost da comunidade:\n\n${post.content}',
      images: post.images,
      createdAt: DateTime.now(),
      hashtags: post.hashtags,
      likes: 0,
      comments: 0,
      isSameBike: false,
    );

    Provider.of<SocialFeedProvider>(context, listen: false)
        .prependPost(newPost);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post compartilhado no seu feed.')),
    );
  }

  String _shareMessage(Post post) {
    final preview = post.content.length > 180
        ? '${post.content.substring(0, 180)}...'
        : post.content;
    return 'Confira este post no Giro Certo:\n\n$preview';
  }

  String _shareMessageForChannel(Post post, String channel) {
    final preview = post.content.length > 160
        ? '${post.content.substring(0, 160)}...'
        : post.content;
    switch (channel) {
      case 'whatsapp':
        return 'Vi este conteúdo na Comunidade Giro Certo e lembrei de você:\n\n$preview';
      case 'instagram':
        return 'Post da Comunidade Giro Certo:\n\n$preview\n\n#GiroCerto #Comunidade';
      case 'messages':
        return 'Olha essa dica da Comunidade Giro Certo:\n\n$preview';
      case 'snapchat':
        return 'Momento Giro Certo:\n\n$preview';
      default:
        return _shareMessage(post);
    }
  }

  Future<void> _trackEngagement(String action) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_engagementMetricsKey) ?? const [];
    final next = <String, int>{};
    for (final row in raw) {
      final parts = row.split(':');
      if (parts.length != 2) continue;
      next[parts.first] = int.tryParse(parts.last) ?? 0;
    }
    next[action] = (next[action] ?? 0) + 1;
    await prefs.setStringList(
      _engagementMetricsKey,
      next.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }
}
