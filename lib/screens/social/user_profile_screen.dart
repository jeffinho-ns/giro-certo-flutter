import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/colors.dart';

/// Perfil público de outro usuário (skeleton: lista de posts do usuário).
class UserProfileScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.racingOrange.withOpacity(0.2),
              backgroundImage: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
                  ? NetworkImage(userAvatarUrl!)
                  : null,
              child: userAvatarUrl == null || userAvatarUrl!.isEmpty
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.racingOrange,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (userBikeModel != null && userBikeModel!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                userBikeModel!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Publicações deste usuário em breve.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
