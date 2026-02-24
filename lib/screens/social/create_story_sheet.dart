import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

/// Bottom sheet para criar story: Câmera ou Galeria.
/// Abre o ecrã de pré-visualização/edição para adicionar texto e publicar.
class CreateStorySheet extends StatelessWidget {
  const CreateStorySheet({super.key});

  /// Retorna true se uma story foi publicada, false se cancelou, ou um Map com openPreview.
  static Future<dynamic> show(BuildContext context) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
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
                  onTap: () => _pickAndOpenPreview(context, user.id, user.name, user.photoUrl, ImageSource.camera),
                ),
                const SizedBox(width: 24),
                _OptionTile(
                  icon: LucideIcons.image,
                  label: 'Galeria',
                  onTap: () => _pickAndOpenPreview(context, user.id, user.name, user.photoUrl, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Escolhe imagem e abre o ecrã de pré-visualização para editar texto e publicar.
  static Future<void> _pickAndOpenPreview(
    BuildContext context,
    String userId,
    String userName,
    String? userAvatarUrl,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source);
    if (x == null || !context.mounted) return;

    Navigator.of(context).pop({'openPreview': true, 'imagePath': x.path, 'userId': userId, 'userName': userName, 'userAvatarUrl': userAvatarUrl});
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
