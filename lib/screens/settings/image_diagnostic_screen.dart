import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';

/// Ecrã de diagnóstico para verificar o que a API retorna (posts, stories).
class ImageDiagnosticScreen extends StatefulWidget {
  const ImageDiagnosticScreen({super.key});

  @override
  State<ImageDiagnosticScreen> createState() => _ImageDiagnosticScreenState();
}

class _ImageDiagnosticScreenState extends State<ImageDiagnosticScreen> {
  String _output = 'A carregar...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _loading = true;
      _output = 'A carregar...';
    });
    try {
      final sb = StringBuffer();

      // Posts
      sb.writeln('=== POSTS ===');
      final posts = await ApiService.getPosts(limit: 5, offset: 0);
      sb.writeln('Total: ${posts.length}');
      for (var i = 0; i < posts.length && i < 3; i++) {
        final p = posts[i];
        final images = p['images'];
        sb.writeln('\nPost ${i + 1} (id: ${p['id']}):');
        final content = p['content'] as String? ?? '';
        sb.writeln('  content: ${content.length > 40 ? "${content.substring(0, 40)}..." : content}');
        sb.writeln('  images: $images');
        if (images != null) sb.writeln('  images type: ${images.runtimeType}');
        if (images is List && images.isNotEmpty) {
          sb.writeln('  primeira URL: ${images[0]}');
        }
      }
      if (posts.isEmpty) sb.writeln('(nenhum post)');

      // Stories
      sb.writeln('\n\n=== STORIES ===');
      final stories = await ApiService.getStories();
      sb.writeln('Total: ${stories.length}');
      for (var i = 0; i < stories.length && i < 3; i++) {
        final s = stories[i];
        final mediaUrl = s['mediaUrl'] ?? s['media_url'];
        sb.writeln('\nStory ${i + 1} (id: ${s['id']}):');
        sb.writeln('  mediaUrl: $mediaUrl');
      }
      if (stories.isEmpty) sb.writeln('(nenhum story)');

      sb.writeln('\n\n=== CONCLUSÃO ===');
      final hasPostImages = posts.any((p) {
        final imgs = p['images'];
        return imgs is List && imgs.isNotEmpty;
      });
      final hasStoryMedia = stories.any((s) {
        final m = s['mediaUrl'] ?? s['media_url'];
        return m != null && m.toString().trim().isNotEmpty;
      });
      sb.writeln('Posts com imagens: ${hasPostImages ? "SIM" : "NÃO"}');
      sb.writeln('Stories com mediaUrl: ${hasStoryMedia ? "SIM" : "NÃO"}');

      if (!hasPostImages && !hasStoryMedia) {
        sb.writeln('\n⚠️ Nenhuma imagem/mediaUrl encontrada.');
        sb.writeln('Possíveis causas:');
        sb.writeln('1. API sem Firebase configurado + tabela Image vazia');
        sb.writeln('2. Posts/stories criados sem imagem ou upload falhou');
        sb.writeln('3. Firebase Storage: regras não permitem leitura');
      }

      setState(() {
        _output = sb.toString();
        _loading = false;
      });
    } catch (e, st) {
      setState(() {
        _output = 'Erro: $e\n\n$st';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Imagens'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loading ? null : _runDiagnostic,
          ),
          IconButton(
            icon: const Icon(LucideIcons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _output));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copiado para a área de transferência')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.racingOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _output,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
    );
  }
}
