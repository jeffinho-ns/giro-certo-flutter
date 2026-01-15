import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/post.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike!;
    final posts = MockDataService.getMockPosts(bike.model);
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
          children: [
            // Header
            const ModernHeader(
              title: 'Comunidade',
              showBackButton: false,
            ),
            
            // Lista de posts
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildModernPostCard(post, theme);
                },
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildModernPostCard(Post post, ThemeData theme) {
    final timeAgo = _getTimeAgo(post.createdAt);
    
    return Builder(
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: post.isSameBike
                  ? AppColors.racingOrange.withOpacity(0.4)
                  : theme.dividerColor,
              width: post.isSameBike ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: post.isSameBike
                    ? AppColors.racingOrange.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do post
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.racingOrange,
                            AppColors.racingOrangeLight,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          post.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (post.isSameBike) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.racingOrange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Mesma Moto',
                                    style: TextStyle(
                                      color: AppColors.racingOrange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                post.userBikeModel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeAgo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Conteúdo do post
                Text(
                  post.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Ações
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.heart,
                      label: post.likes.toString(),
                      onTap: () {},
                    ),
                    const SizedBox(width: 24),
                    _buildActionButton(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.messageCircle,
                      label: post.comments.toString(),
                      onTap: () {},
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(LucideIcons.share2),
                      color: theme.iconTheme.color,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: theme.iconTheme.color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }
}
