import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StoryViewScreen extends StatefulWidget {
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late int _currentIndex;
  late Timer _timer;
  double _progress = 0.0;
  static const Duration _storyDuration = Duration(seconds: 15);
  static const int _storyCount = 4;
  final Set<int> _likedStories = {};
  final Map<int, int> _likeCount = {0: 12, 1: 45, 2: 8, 3: 32};

  final List<Map<String, String>> _stories = [
    {'image': 'assets/images/Story-1.jpg', 'user': 'Abdul'},
    {'image': 'assets/images/Story-2.jpg', 'user': 'Chris'},
    {'image': 'assets/images/Story-3.jpg', 'user': 'General'},
    {'image': 'assets/images/Story-4.jpg', 'user': 'Oyin Dolapo'},
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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

  @override
  Widget build(BuildContext context) {
    final story = _stories[_currentIndex];

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
              child: Image.asset(
                story['image']!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(
                        LucideIcons.image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
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
                      (index) => Expanded(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          Text(
                            story['user']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_currentIndex + 1}/${_storyCount}',
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
                            _likeCount[_currentIndex] = (_likeCount[_currentIndex] ?? 0) - 1;
                          } else {
                            _likedStories.add(_currentIndex);
                            _likeCount[_currentIndex] = (_likeCount[_currentIndex] ?? 0) + 1;
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

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Comentários',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _comments.length,
                  itemBuilder: (context, i) {
                    final c = _comments[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['user']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['text']!,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Divider(color: theme.dividerColor.withOpacity(0.3)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Adicionar comentário...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(LucideIcons.send),
                        color: Colors.white,
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
    );
  }
}
