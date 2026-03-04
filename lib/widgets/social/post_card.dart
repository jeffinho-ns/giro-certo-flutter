import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/post.dart';
import '../../models/post_type.dart';
import '../../models/reaction_type.dart';
import '../../utils/colors.dart';
import '../../utils/social_formatters.dart';
import '../api_image.dart';

class SocialPostCard extends StatelessWidget {
  final Post post;
  final int likeCount;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback onOptions;
  final void Function(ReactionType type)? onReaction;
  final void Function(String hashtag)? onHashtagTap;

  const SocialPostCard({
    super.key,
    required this.post,
    required this.likeCount,
    required this.isLiked,
    required this.onLike,
    required this.onComments,
    required this.onOptions,
    this.onReaction,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = SocialFormatters.timeAgo(post.createdAt);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: theme.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: post.userAvatarUrl != null &&
                            post.userAvatarUrl!.isNotEmpty
                        ? ApiImage(
                            url: post.userAvatarUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.racingOrange.withOpacity(0.2),
                            alignment: Alignment.center,
                            child: Text(
                              (post.userName.isNotEmpty
                                      ? post.userName[0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.racingOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: post.isDeliveryAuthor
                                  ? Colors.blue.withOpacity(0.2)
                                  : AppColors.racingOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              post.isDeliveryAuthor ? 'Delivery' : 'Piloto',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: post.isDeliveryAuthor
                                    ? Colors.blue.shade700
                                    : AppColors.racingOrange,
                              ),
                            ),
                          ),
                          if (post.isSameBike) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.racingOrange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Mesma moto',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.racingOrange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          if (post.postType != PostType.normal) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                post.postType.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              '${post.userBikeModel.isNotEmpty ? "${post.userBikeModel} • " : ""}$timeAgo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.65),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.moreHorizontal),
                  iconSize: 20,
                  onPressed: onOptions,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
            if (post.hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: post.hashtags.map((tag) {
                  return GestureDetector(
                    onTap: () => onHashtagTap?.call(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.racingOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.racingOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (post.images != null && post.images!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _openFullScreenImage(context, post.images!.first),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: post.images!.first.startsWith('assets/')
                      ? Image.asset(
                          post.images!.first,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholderImage(theme),
                        )
                      : SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: ApiImage(
                            url: post.images!.first,
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _placeholderImage(theme),
                          ),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/images/Heart.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isLiked
                            ? Colors.red
                            : (theme.iconTheme.color ?? Colors.grey),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '$likeCount',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
                if (onReaction != null) ...[
                  const SizedBox(width: 16),
                  _reactionChip(
                    theme,
                    LucideIcons.mapPin,
                    post.reactions[ReactionType.boaRota] ?? 0,
                    () => onReaction!(ReactionType.boaRota),
                  ),
                  const SizedBox(width: 8),
                  _reactionChip(
                    theme,
                    LucideIcons.wrench,
                    post.reactions[ReactionType.boaDica] ?? 0,
                    () => onReaction!(ReactionType.boaDica),
                  ),
                ],
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: onComments,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/images/Chat.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        theme.iconTheme.color ?? Colors.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '${post.comments}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reactionChip(
    ThemeData theme,
    IconData icon,
    int count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.iconTheme.color ?? Colors.grey),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _placeholderImage(ThemeData theme) {
    return Container(
      height: 200,
      color: theme.dividerColor,
      child: Center(
        child: Icon(
          LucideIcons.image,
          size: 48,
          color: theme.iconTheme.color?.withOpacity(0.4),
        ),
      ),
    );
  }

  static void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: imageUrl.startsWith('assets/')
                          ? Image.asset(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                LucideIcons.imageOff,
                                size: 64,
                                color: Colors.white54,
                              ),
                            )
                          : ApiImage(
                              url: imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                LucideIcons.imageOff,
                                size: 64,
                                color: Colors.white54,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
