import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../models/moment.dart';
import '../../services/moments_service.dart';
import '../../utils/colors.dart';
import '../../widgets/api_image.dart';
import 'create_moment_screen.dart';
import 'moment_comments_sheet.dart';

/// Feed estilo Reels: vídeos em página vertical, full-screen, com botões
/// laterais de like, comentar, repostar.
class MomentosScreen extends StatefulWidget {
  /// Quando informado, faz scroll direto para o vídeo solicitado (deep link
  /// a partir do perfil).
  final String? initialMomentId;

  const MomentosScreen({super.key, this.initialMomentId});

  @override
  State<MomentosScreen> createState() => _MomentosScreenState();
}

class _MomentosScreenState extends State<MomentosScreen> {
  final PageController _pageController = PageController();
  List<Moment> _moments = [];
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    setState(() => _loading = true);
    final feed =
        await MomentsService.getFeed(currentUserId: appState.user?.id);
    if (!mounted) return;
    setState(() {
      _moments = feed;
      _loading = false;
      if (widget.initialMomentId != null) {
        final idx =
            feed.indexWhere((m) => m.id == widget.initialMomentId);
        if (idx >= 0) _currentIndex = idx;
      } else if (_currentIndex >= feed.length) {
        _currentIndex = feed.isEmpty ? 0 : feed.length - 1;
      }
    });
    if (widget.initialMomentId != null && _moments.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }
  }

  Future<void> _openCreate() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para publicar momentos.')),
      );
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateMomentScreen()),
    );
    if (result == true) {
      await _load();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  Future<void> _onLike(Moment moment) async {
    final updated = await MomentsService.toggleLike(moment);
    if (!mounted) return;
    setState(() {
      final idx = _moments.indexWhere((m) => m.id == moment.id);
      if (idx >= 0) _moments[idx] = updated;
    });
  }

  Future<void> _onRepost(Moment moment) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null) return;
    if (moment.userId == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não pode repostar o seu próprio momento.')),
      );
      return;
    }
    final updated = await MomentsService.repost(
      original: moment,
      currentUserId: user.id,
      currentUserName: user.name,
      currentUserAvatarUrl: user.photoUrl,
      currentUserPilotProfile: user.pilotProfile,
    );
    if (!mounted) return;
    setState(() {
      final idx = _moments.indexWhere((m) => m.id == moment.id);
      if (idx >= 0) _moments[idx] = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Repostado no seu perfil.')),
    );
    await _load();
  }

  void _openComments(Moment moment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MomentCommentsSheet(moment: moment),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_moments.isEmpty)
            _buildEmpty()
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: _moments.length,
              itemBuilder: (context, i) {
                final moment = _moments[i];
                final isActive = i == _currentIndex;
                return _MomentItem(
                  moment: moment,
                  isActive: isActive,
                  onLike: () => _onLike(moment),
                  onRepost: () => _onRepost(moment),
                  onComment: () => _openComments(moment),
                );
              },
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _topIconButton(
                    LucideIcons.arrowLeft,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).maybePop();
                      } else {
                        Provider.of<NavigationProvider>(context,
                                listen: false)
                            .navigateTo(2);
                      }
                    },
                  ),
                  const Spacer(),
                  Text(
                    'Momentos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  _topIconButton(LucideIcons.plus, onTap: _openCreate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.racingOrange.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.sparkles,
                  color: AppColors.racingOrange, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'Os Momentos ainda estão vazios',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seja o primeiro a publicar um vídeo de até 2 minutos.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(LucideIcons.video),
              label: const Text('Publicar momento'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.racingOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentItem extends StatefulWidget {
  final Moment moment;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onRepost;
  final VoidCallback onComment;

  const _MomentItem({
    required this.moment,
    required this.isActive,
    required this.onLike,
    required this.onRepost,
    required this.onComment,
  });

  @override
  State<_MomentItem> createState() => _MomentItemState();
}

class _MomentItemState extends State<_MomentItem> {
  VideoPlayerController? _controller;
  bool _muted = false;
  bool _showHeartBurst = false;
  Timer? _heartTimer;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _MomentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moment.videoUrl != widget.moment.videoUrl) {
      _disposeController();
      _initController();
    } else if (widget.isActive != oldWidget.isActive) {
      _applyPlayState();
    }
  }

  Future<void> _initController() async {
    final url = widget.moment.videoUrl;
    if (url.isEmpty) return;
    VideoPlayerController controller;
    if (url.startsWith('http')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else if (url.startsWith('asset')) {
      controller = VideoPlayerController.asset(url);
    } else {
      controller = VideoPlayerController.file(File(url));
    }
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      _applyPlayState();
      if (mounted) setState(() {});
    } catch (_) {
      // mantém estado vazio (mostraremos só a thumb)
    }
  }

  void _applyPlayState() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (widget.isActive) {
      c.play();
      c.setVolume(_muted ? 0 : 1);
    } else {
      c.pause();
    }
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      _controller?.setVolume(_muted ? 0 : 1);
    });
  }

  void _triggerHeartBurst() {
    setState(() => _showHeartBurst = true);
    _heartTimer?.cancel();
    _heartTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _heartTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;
    final c = _controller;
    final isReady = c != null && c.value.isInitialized;

    return GestureDetector(
      onTap: () {
        final c = _controller;
        if (c == null || !c.value.isInitialized) return;
        if (c.value.isPlaying) {
          c.pause();
        } else {
          c.play();
        }
        setState(() {});
      },
      onDoubleTap: () {
        if (!m.likedByMe) widget.onLike();
        _triggerHeartBurst();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          if (isReady)
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio == 0
                    ? 9 / 16
                    : c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            )
          else if (m.thumbnailUrl != null && m.thumbnailUrl!.isNotEmpty)
            Center(
              child: m.thumbnailUrl!.startsWith('http')
                  ? ApiImage(url: m.thumbnailUrl!, fit: BoxFit.cover)
                  : Image.file(File(m.thumbnailUrl!), fit: BoxFit.cover),
            )
          else
            const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          // Gradient overlay para legibilidade
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x66000000),
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.55, 0.75, 1],
                ),
              ),
            ),
          ),
          // Burst do coração (double-tap)
          if (_showHeartBurst)
            const Center(
              child: _HeartBurst(),
            ),
          if (isReady)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: c,
                builder: (context, value, _) {
                  final progress = value.duration.inMilliseconds == 0
                      ? 0.0
                      : value.position.inMilliseconds /
                          value.duration.inMilliseconds;
                  return LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 2,
                    backgroundColor: Colors.white24,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.racingOrange),
                  );
                },
              ),
            ),
          // Texto do autor + caption
          Positioned(
            left: 16,
            right: 84,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.originalAuthorName != null) ...[
                  Row(
                    children: [
                      Icon(LucideIcons.repeat2,
                          size: 14,
                          color: Colors.white.withOpacity(0.85)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Repostou de @${m.originalAuthorName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white.withOpacity(0.18),
                      ),
                      child: ClipOval(
                        child: m.userAvatarUrl != null &&
                                m.userAvatarUrl!.isNotEmpty
                            ? ApiImage(url: m.userAvatarUrl!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  m.userName.isEmpty
                                      ? 'U'
                                      : m.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '@${m.userName.replaceAll(' ', '').toLowerCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (m.caption.isNotEmpty)
                  Text(
                    m.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.3),
                  ),
                if (m.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: m.hashtags
                        .take(6)
                        .map((h) => Text(
                              '#$h',
                              style: TextStyle(
                                color: AppColors.racingOrangeLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          // Ações laterais
          Positioned(
            right: 12,
            bottom: 24,
            child: Column(
              children: [
                _ActionButton(
                  icon: m.likedByMe
                      ? LucideIcons.heart
                      : LucideIcons.heart,
                  filled: m.likedByMe,
                  color: m.likedByMe ? AppColors.racingOrange : Colors.white,
                  label: _formatCount(m.likes),
                  onTap: widget.onLike,
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: LucideIcons.messageCircle,
                  color: Colors.white,
                  label: _formatCount(m.comments),
                  onTap: widget.onComment,
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: LucideIcons.repeat2,
                  color: m.repostedByMe
                      ? AppColors.racingOrange
                      : Colors.white,
                  label: _formatCount(m.reposts),
                  onTap: widget.onRepost,
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: _muted
                      ? LucideIcons.volumeX
                      : LucideIcons.volume2,
                  color: Colors.white,
                  label: '',
                  onTap: _toggleMute,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.black.withOpacity(0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeartBurst extends StatefulWidget {
  const _HeartBurst();

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        final t = _ac.value;
        final scale = 0.6 + (1.4 * (1 - (t - 0.5).abs() * 2));
        final opacity = 1.0 - t;
        return Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.scale(
            scale: scale,
            child: Icon(
              LucideIcons.heart,
              size: 120,
              color: AppColors.racingOrange,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
