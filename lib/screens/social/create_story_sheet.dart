import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/social_service.dart';

/// Bottom sheet para criar story: Câmera ou Galeria.
class CreateStorySheet extends StatelessWidget {
  const CreateStorySheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateStorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<AppStateProvider>(context).user;
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nova story',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OptionTile(
                  icon: LucideIcons.camera,
                  label: 'Câmera',
                  onTap: () => _pickAndCreate(context, user.id, user.name, user.photoUrl, ImageSource.camera),
                ),
                const SizedBox(width: 24),
                _OptionTile(
                  icon: LucideIcons.image,
                  label: 'Galeria',
                  onTap: () => _pickAndCreate(context, user.id, user.name, user.photoUrl, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Future<void> _pickAndCreate(
    BuildContext context,
    String userId,
    String userName,
    String? userAvatarUrl,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source);
    if (x == null || !context.mounted) return;
    try {
      await SocialService.createStory(
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        mediaUrl: x.path,
      );
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao publicar story')),
        );
      }
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
