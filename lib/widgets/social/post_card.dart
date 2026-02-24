import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/post.dart';
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

  const SocialPostCard({
    super.key,
    required this.post,
    required this.likeCount,
    required this.isLiked,
    required this.onLike,
    required this.onComments,
    required this.onOptions,
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
                      Text(
                        '${post.userBikeModel} • $timeAgo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.65),
                          fontSize: 12,
                        ),
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
            if (post.images != null && post.images!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
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
}
