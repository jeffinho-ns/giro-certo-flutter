import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/story.dart';
import '../../utils/colors.dart';

/// Tile "Publicar" (index 0) ou tile de um story.
class StoryTile extends StatelessWidget {
  final Story? story;
  final int? storyIndex;
  final List<Story>? allStories;
  final VoidCallback? onAddTap;
  final VoidCallback? onStoryTap;

  const StoryTile({
    super.key,
    this.story,
    this.storyIndex,
    this.allStories,
    this.onAddTap,
    this.onStoryTap,
  });

  bool get isAddTile => story == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isAddTile) {
      return Center(
        child: GestureDetector(
          onTap: onAddTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.plus,
                  size: 32,
                  color: AppColors.racingOrange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Publicar',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final s = story!;
    return Center(
      child: GestureDetector(
        onTap: onStoryTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.racingOrange,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _StoryImage(url: s.mediaUrl, theme: theme),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 90,
              child: Text(
                s.userName,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryImage extends StatelessWidget {
  final String url;
  final ThemeData theme;

  const _StoryImage({required this.url, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isAsset = url.startsWith('assets/');
    if (isAsset) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: theme.cardColor,
          child: const Icon(LucideIcons.image),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: theme.cardColor,
        child: const Icon(LucideIcons.image),
      ),
    );
  }
}
