import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/story.dart';
import '../../utils/colors.dart';

class StoryViewScreen extends StatefulWidget {
  final int initialIndex;
  /// Quando fornecido, usa dados reais em vez da lista fixa.
  final List<Story>? stories;

  const StoryViewScreen({
    super.key,
    this.initialIndex = 0,
    this.stories,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late int _currentIndex;
  late Timer _timer;
  double _progress = 0.0;
  static const Duration _storyDuration = Duration(seconds: 15);
  late int _storyCount;
  final Set<int> _likedStories = {};
  final Map<int, int> _likeCount = {};

  /// Lista legada (quando stories == null).
  final List<Map<String, String>> _legacyStories = [
    {'image': 'assets/images/Story-1.jpg', 'user': 'Abdul'},
    {'image': 'assets/images/Story-2.jpg', 'user': 'Chris'},
    {'image': 'assets/images/Story-3.jpg', 'user': 'General'},
    {'image': 'assets/images/Story-4.jpg', 'user': 'Oyin Dolapo'},
  ];

  List<Story> get _storiesList => widget.stories ?? [];
  bool get _useStories => widget.stories != null && widget.stories!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_useStories) {
      _storyCount = widget.stories!.length;
      for (var i = 0; i < _storyCount; i++) {
        _likeCount[i] = widget.stories![i].likeCount;
      }
    } else {
      _storyCount = _legacyStories.length;
      _likeCount.addAll({0: 12, 1: 45, 2: 8, 3: 32});
    }
    _currentIndex = widget.initialIndex.clamp(0, _storyCount - 1);
    _startTimer();
  }

  void _startTimer() {
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 50 / _storyDuration.inMilliseconds;
        if (_progress >= 1.0) {
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    _timer.cancel();
    if (_currentIndex < _storyCount - 1) {
      setState(() => _currentIndex++);
      _startTimer();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    _timer.cancel();
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startTimer();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showCommentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentBottomSheet(
        storyIndex: _currentIndex,
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _currentStoryImage {
    if (_useStories) return _storiesList[_currentIndex].mediaUrl;
    return _legacyStories[_currentIndex]['image']!;
  }

  String get _currentStoryUser {
    if (_useStories) return _storiesList[_currentIndex].userName;
    return _legacyStories[_currentIndex]['user']!;
  }

  Widget _buildStoryImage() {
    final url = _currentStoryImage;
    final isAsset = url.startsWith('assets/');
    if (isAsset) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black87,
            child: const Center(
              child: Icon(LucideIcons.image, color: Colors.white54, size: 64),
            ),
          );
        },
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black87,
          child: const Center(
            child: Icon(LucideIcons.image, color: Colors.white54, size: 64),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > width * 2 / 3) {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // Imagem da story em tela cheia
            Positioned.fill(
              child: _buildStoryImage(),
            ),

            // Overlay gradiente no topo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Progresso no topo
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: List.generate(
                      _storyCount,
                      (int index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              minHeight: 2.5,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation(
                                index < _currentIndex
                                    ? Colors.white
                                    : (index == _currentIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5)),
                              ),
                              value: index < _currentIndex
                                  ? 1.0
                                  : (index == _currentIndex ? _progress : 0.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Header com usuário e botão fechar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          Text(
                            _currentStoryUser,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_currentIndex + 1}/$_storyCount',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SafeArea(
                        child: IconButton(
                          icon: const Icon(LucideIcons.x),
                          color: Colors.white,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botões no canto inferior direito
            Positioned(
              bottom: 40,
              right: 16,
              child: SafeArea(
                child: Column(
                  children: [
                    // Botão Curtir
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_likedStories.contains(_currentIndex)) {
                            _likedStories.remove(_currentIndex);
                            _likeCount[_currentIndex] =
                                (_likeCount[_currentIndex] ?? 0) - 1;
                          } else {
                            _likedStories.add(_currentIndex);
                            _likeCount[_currentIndex] =
                                (_likeCount[_currentIndex] ?? 0) + 1;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/images/Heart.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                _likedStories.contains(_currentIndex)
                                    ? Colors.red
                                    : Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_likeCount[_currentIndex] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botão Comentar
                    GestureDetector(
                      onTap: () {
                        _showCommentBottomSheet();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'assets/images/Chat.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBottomSheet extends StatefulWidget {
  final int storyIndex;

  const _CommentBottomSheet({
    required this.storyIndex,
  });

  @override
  State<_CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<_CommentBottomSheet> {
  final _commentController = TextEditingController();
  final List<Map<String, String>> _comments = [
    {'user': 'João Silva', 'text': 'Muito legal! 🔥'},
    {'user': 'Maria Santos', 'text': 'Adorei essa postagem!'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _comments.add({
          'user': 'Você',
          'text': _commentController.text,
        });
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Comentários',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _comments.length,
                    itemBuilder: (context, i) {
                      final c = _comments[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['user']!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['text']!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              height: 1,
                              color: theme.dividerColor.withOpacity(0.4),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                          decoration: InputDecoration(
                            hintText: 'Adicionar comentário...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: theme.dividerColor.withOpacity(0.6),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: AppColors.racingOrange,
                        borderRadius: BorderRadius.circular(24),
                        child: IconButton(
                          icon: const Icon(LucideIcons.send, size: 20, color: Colors.white),
                          onPressed: _submitComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
