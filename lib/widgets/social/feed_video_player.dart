import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../services/api_service.dart';
import '../../utils/image_url.dart';

/// Player de vídeo para o feed/stories: reproduz automaticamente, **sem áudio**
/// (mudo) e em loop. Pausa sozinho quando sai da área visível para poupar
/// bateria e dados quando há vários vídeos na lista.
class FeedVideoPlayer extends StatefulWidget {
  final String url;

  /// Altura fixa (feed). Se nulo, ocupa todo o espaço disponível (stories).
  final double? height;

  /// Mostra um pequeno ícone indicando que o som está desligado.
  final bool showMutedBadge;

  const FeedVideoPlayer({
    super.key,
    required this.url,
    this.height,
    this.showMutedBadge = true,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _initialized = false;
      _failed = false;
      _setup();
    }
  }

  Future<void> _setup() async {
    final resolved = resolveImageUrl(widget.url);
    if (resolved.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    try {
      final headers = <String, String>{};
      final isAbsolute =
          resolved.startsWith('http://') || resolved.startsWith('https://');
      final isFirebase = resolved.contains('firebasestorage');
      // Conteúdo da própria API (relativo/absoluto) precisa do token; o
      // Firebase Storage já vem com token na própria URL.
      if (!isFirebase) {
        final token = await ApiService.getStoredToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(resolved),
        httpHeaders: isAbsolute && isFirebase ? const {} : headers,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = controller;
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _initialized = true);
      _updatePlayback();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _updatePlayback() {
    final controller = _controller;
    if (controller == null || !_initialized) return;
    if (_visible) {
      if (!controller.value.isPlaying) controller.play();
    } else {
      if (controller.value.isPlaying) controller.pause();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final nowVisible = info.visibleFraction > 0.5;
    if (nowVisible == _visible) return;
    _visible = nowVisible;
    _updatePlayback();
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_failed) {
      content = Container(
        color: Colors.black,
        child: const Center(
          child: Icon(LucideIcons.videoOff, color: Colors.white54, size: 40),
        ),
      );
    } else if (!_initialized || _controller == null) {
      content = Container(
        color: Colors.black,
        child: const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    } else {
      final size = _controller!.value.size;
      content = Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          if (widget.showMutedBadge)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.volumeX,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      );
    }

    final sized = widget.height != null
        ? SizedBox(height: widget.height, width: double.infinity, child: content)
        : content;

    return VisibilityDetector(
      key: ValueKey('feed_video_${widget.url}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(color: theme.cardColor, child: sized),
    );
  }
}
