import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/story.dart';
import '../../providers/social_feed_provider.dart';
import '../../services/social_service.dart';
import '../../utils/colors.dart';

/// Ecrã de pré-visualização e edição da story antes de publicar.
/// Mostra a imagem, permite adicionar texto e só publica ao tocar em "Publicar".
class StoryPreviewEditScreen extends StatefulWidget {
  final String imagePath;
  final String userId;
  final String userName;
  final String? userAvatarUrl;

  const StoryPreviewEditScreen({
    super.key,
    required this.imagePath,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
  });

  /// Retorna a [Story] criada se publicou com sucesso, null se voltou atrás.
  static Future<Story?> push(
    BuildContext context, {
    required String imagePath,
    required String userId,
    required String userName,
    String? userAvatarUrl,
  }) async {
    final result = await Navigator.of(context).push<Story>(
      MaterialPageRoute(
        builder: (_) => StoryPreviewEditScreen(
          imagePath: imagePath,
          userId: userId,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
        ),
      ),
    );
    return result;
  }

  @override
  State<StoryPreviewEditScreen> createState() => _StoryPreviewEditScreenState();
}

class _StoryPreviewEditScreenState extends State<StoryPreviewEditScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPublishing = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              Text(
                'A enviar imagem…',
                style: Theme.of(ctx).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A story só aparece quando o envio terminar.',
                style: Theme.of(ctx).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final Story created = await SocialService.createStory(
        userId: widget.userId,
        userName: widget.userName,
        userAvatarUrl: widget.userAvatarUrl,
        mediaUrl: widget.imagePath,
        caption: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // fecha o diálogo de loading
      Provider.of<SocialFeedProvider>(context, listen: false).prependStory(created);
      Navigator.of(context).pop(created); // volta ao feed e devolve a story
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // fecha o diálogo de loading
        setState(() => _isPublishing = false);
        final message = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Falha ao publicar. Verifica a ligação e tenta novamente.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'Tentar de novo',
              onPressed: () => _publish(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(widget.imagePath);
    final exists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: const Text('Nova story'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isPublishing || !exists ? null : _publish,
              icon: _isPublishing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.send, size: 18),
              label: const Text('Publicar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.racingOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: exists
                    ? Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildErrorImage(theme),
                      )
                    : _buildErrorImage(theme),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: theme.scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adicionar texto (opcional)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Escreve uma legenda para a tua story…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.imageOff, size: 64, color: Colors.white54),
        const SizedBox(height: 16),
        Text(
          'Imagem não encontrada',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          'Volta atrás e escolhe outra imagem.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
