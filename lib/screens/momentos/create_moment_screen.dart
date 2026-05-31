import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/moments_service.dart';
import '../../utils/colors.dart';
import '../../utils/media_capture_permissions.dart';
import '../../widgets/modern_header.dart';

/// Tela para gravar/escolher um vídeo curto e publicá-lo como Moment.
class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  XFile? _selectedFile;
  VideoPlayerController? _previewController;
  String? _thumbnailPath;
  Duration _duration = Duration.zero;
  bool _publishing = false;
  bool _processingVideo = false;

  @override
  void dispose() {
    _captionController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() => _pickVideo(ImageSource.gallery);

  Future<void> _recordVideo() => _pickVideo(ImageSource.camera);

  Future<void> _pickVideo(ImageSource source) async {
    if (_processingVideo) return;

    if (source == ImageSource.camera) {
      final ok = await MediaCapturePermissions.ensureForVideoCapture(context);
      if (!ok || !mounted) return;
    } else {
      final ok = await MediaCapturePermissions.ensureForGallery(context);
      if (!ok || !mounted) return;
    }

    setState(() => _processingVideo = true);
    try {
      final file = await _picker.pickVideo(
        source: source,
        maxDuration: MomentsService.maxDuration,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null || !mounted) return;

      await _previewController?.dispose();
      _previewController = null;

      final controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      final duration = controller.value.duration;

      if (duration > MomentsService.maxDuration) {
        await controller.dispose();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'O vídeo passa de ${MomentsService.maxDuration.inMinutes} minutos. Escolha um vídeo mais curto.',
            ),
          ),
        );
        return;
      }

      controller.setLooping(true);
      controller.setVolume(0);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _selectedFile = file;
        _previewController = controller;
        _duration = duration;
        _thumbnailPath = null;
      });

      unawaited(_generateThumbnailAsync(file.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar vídeo: $e')),
      );
    } finally {
      if (mounted) setState(() => _processingVideo = false);
    }
  }

  Future<void> _generateThumbnailAsync(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 600,
        quality: 75,
      );
      if (!mounted || thumbPath == null) return;
      setState(() => _thumbnailPath = thumbPath);
    } catch (_) {
      // Miniatura opcional — publicação funciona sem ela.
    }
  }

  Future<void> _publish() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null || _selectedFile == null) return;
    if (_duration <= Duration.zero ||
        _duration > MomentsService.maxDuration) return;

    setState(() => _publishing = true);
    try {
      final caption = _captionController.text.trim();
      final hashtags = RegExp(r'#(\w+)')
          .allMatches(caption)
          .map((m) => m.group(1) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      await MomentsService.publishMoment(
        userId: user.id,
        userName: user.name,
        userAvatarUrl: user.photoUrl,
        userPilotProfile: user.pilotProfile,
        videoPath: _selectedFile!.path,
        thumbnailPath: _thumbnailPath,
        caption: caption,
        duration: _duration,
        hashtags: hashtags,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível publicar: $e')),
      );
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVideo = _selectedFile != null && _previewController != null;
    final busy = _processingVideo || _publishing;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                ModernHeader(
                  title: 'Novo Momento',
                  showBackButton: true,
                  onBackPressed: busy
                      ? () {}
                      : () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vídeos de até ${MomentsService.maxDuration.inMinutes} min, formato vertical para melhor visualização.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AspectRatio(
                          aspectRatio: 9 / 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.racingOrange.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasVideo
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _previewController!
                                              .value.size.width,
                                          height: _previewController!
                                              .value.size.height,
                                          child:
                                              VideoPlayer(_previewController!),
                                        ),
                                      ),
                                      Positioned(
                                        left: 12,
                                        top: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _formatDuration(_duration),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.video,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 42,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Escolha um vídeo da galeria\nou grave agora.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: busy ? null : _pickFromGallery,
                                icon: const Icon(LucideIcons.image, size: 18),
                                label: const Text('Galeria'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.racingOrange,
                                  side: BorderSide(
                                    color: AppColors.racingOrange
                                        .withOpacity(0.6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: busy ? null : _recordVideo,
                                icon: const Icon(LucideIcons.camera, size: 18),
                                label: const Text('Gravar'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.racingOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Legenda',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _captionController,
                          maxLines: 3,
                          maxLength: 280,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            hintText:
                                'Conte sobre este momento (use #hashtags para alcance)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: (_selectedFile == null || busy)
                                ? null
                                : _publish,
                            icon: _publishing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(LucideIcons.send),
                            label: Text(_publishing
                                ? 'Publicando...'
                                : 'Publicar momento'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.racingOrange,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_processingVideo)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.racingOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A processar vídeo...',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
