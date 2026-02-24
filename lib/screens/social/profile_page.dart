import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/social_feed_provider.dart';
import '../../models/story.dart';
import '../../models/post.dart';
import '../../models/bike.dart';
import '../../utils/colors.dart';
import 'story_view_screen.dart';
import '../settings/settings_screen.dart';
import '../garage/garage_screen.dart';
import '../../services/api_service.dart';
import '../../utils/image_url.dart';
import '../../widgets/api_image.dart';
import 'follow_list_screen.dart';

const String _coverKeyPrefix = 'profile_cover_';
const String _avatarKeyPrefix = 'profile_avatar_';

/// Página de perfil unificada para todos os tipos de utilizador.
/// Layout moderno com capa e foto de perfil editáveis.
class ProfilePage extends StatefulWidget {
  /// Se null, mostra o perfil do utilizador logado.
  final String? userId;
  final String? userName;
  final String? userAvatarUrl;
  final String? userBikeModel;

  const ProfilePage({
    super.key,
    this.userId,
    this.userName,
    this.userAvatarUrl,
    this.userBikeModel,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _coverPath;
  String? _avatarPath;
  bool _loadingCover = false;
  bool _loadingAvatar = false;
  bool _hasPendingFollowRequest = false;
  Map<String, dynamic>? _loadedProfile;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLocalImages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (widget.userId == null || widget.userId == appState.user?.id) {
        _loadOwnProfile();
      } else {
        _loadPendingFollowRequestState();
        _loadOtherUserProfile();
      }
    });
  }

  Future<void> _loadOwnProfile() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final uid = appState.user?.id;
    if (uid == null) return;
    setState(() => _loadingProfile = true);
    try {
      final profile = await ApiService.getUserProfile(uid);
      if (mounted) {
        setState(() {
          _loadedProfile = profile;
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadOtherUserProfile() async {
    final uid = widget.userId;
    if (uid == null) return;
    setState(() => _loadingProfile = true);
    try {
      final profile = await ApiService.getUserProfile(uid);
      if (mounted && widget.userId == uid) {
        setState(() {
          _loadedProfile = profile;
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadPendingFollowRequestState() async {
    final ids = await ApiService.getSentFollowRequestTargetIds();
    if (mounted && widget.userId != null) {
      setState(() => _hasPendingFollowRequest = ids.contains(widget.userId));
    }
  }

  void _openFollowList(String userId, {required bool isFollowers}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: userId,
          title: isFollowers ? 'Seguidores' : 'A seguir',
          isFollowers: isFollowers,
        ),
      ),
    );
  }

  Future<void> _sendFollowRequestFromProfile() async {
    final uid = widget.userId;
    if (uid == null || _hasPendingFollowRequest) return;
    setState(() => _hasPendingFollowRequest = true);
    final success = await ApiService.sendFollowRequest(uid);
    if (!success && mounted) setState(() => _hasPendingFollowRequest = false);
  }

  Future<void> _loadLocalImages() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final uid = widget.userId ?? appState.user?.id ?? '';
    if (uid.isEmpty || widget.userId != null) return;
    final prefs = await SharedPreferences.getInstance();
    String? cover = prefs.getString('$_coverKeyPrefix$uid');
    String? avatar = prefs.getString('$_avatarKeyPrefix$uid');
    if (cover != null && !await File(cover).exists()) {
      await prefs.remove('$_coverKeyPrefix$uid');
      cover = null;
    }
    if (avatar != null && !await File(avatar).exists()) {
      await prefs.remove('$_avatarKeyPrefix$uid');
      avatar = null;
    }
    if (mounted) setState(() {
      _coverPath = cover;
      _avatarPath = avatar;
    });
  }

  Future<String?> _copyToPermanentStorage(String sourcePath, String prefix, String uid) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final profileDir = Directory(p.join(dir.path, 'profile_photos'));
      if (!await profileDir.exists()) await profileDir.create(recursive: true);
      final ext = p.extension(sourcePath);
      final destPath = p.join(profileDir.path, '${prefix}_${uid}_${DateTime.now().millisecondsSinceEpoch}$ext');
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickCover() async {
    if (_loadingCover) return;
    setState(() => _loadingCover = true);
    final source = await _showImageSourceSheet(context, 'Alterar capa');
    if (source == null || !mounted) {
      setState(() => _loadingCover = false);
      return;
    }
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (x == null || !mounted) {
      setState(() => _loadingCover = false);
      return;
    }
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final uid = appState.user?.id ?? '';
    final permanentPath = await _copyToPermanentStorage(x.path, 'cover', uid);
    final pathToSave = permanentPath ?? x.path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_coverKeyPrefix$uid', pathToSave);
    final coverUrl = await ApiService.uploadProfileImage(pathToSave, type: 'cover');
    if (coverUrl != null && appState.user != null) {
      try {
        await ApiService.updateUserProfile(coverUrl: coverUrl);
      } catch (_) {}
    }
    if (mounted) setState(() {
      _coverPath = pathToSave;
      _loadingCover = false;
    });
  }

  Future<void> _pickAvatar() async {
    if (_loadingAvatar) return;
    setState(() => _loadingAvatar = true);
    final source = await _showImageSourceSheet(context, 'Alterar foto de perfil');
    if (source == null || !mounted) {
      setState(() => _loadingAvatar = false);
      return;
    }
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, maxWidth: 600, imageQuality: 90);
    if (x == null || !mounted) {
      setState(() => _loadingAvatar = false);
      return;
    }
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final uid = appState.user?.id ?? '';
    final permanentPath = await _copyToPermanentStorage(x.path, 'avatar', uid);
    final pathToSave = permanentPath ?? x.path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_avatarKeyPrefix$uid', pathToSave);

    final url = await ApiService.uploadProfileImage(pathToSave, type: 'avatar');
    if (url != null && appState.user != null) {
      try {
        final updated = await ApiService.updateUserProfile(photoUrl: url);
        appState.setUser(updated);
      } catch (_) {}
    }

    if (mounted) setState(() {
      _avatarPath = pathToSave;
      _loadingAvatar = false;
    });
  }

  Future<ImageSource?> _showImageSourceSheet(BuildContext context, String title) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _handleFromName(String name) {
    if (name.isEmpty) return '@utilizador';
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return '@${slug.isNotEmpty ? slug : 'user'}';
  }

  Bike? _bikeFromLoaded(Map<String, dynamic>? b) {
    if (b == null) return null;
    final id = b['id'] as String? ?? '';
    final model = b['model'] as String? ?? '';
    final brand = b['brand'] as String? ?? '';
    final plate = b['plate'] as String? ?? '';
    if (id.isEmpty && model.isEmpty && brand.isEmpty) return null;
    return Bike(
      id: id.isNotEmpty ? id : '1',
      model: model.isNotEmpty ? model : 'Moto',
      brand: brand.isNotEmpty ? brand : '',
      plate: plate,
      currentKm: 0,
      oilType: '',
      frontTirePressure: 2.5,
      rearTirePressure: 2.8,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final feed = Provider.of<SocialFeedProvider>(context);
    final theme = Theme.of(context);

    final isOwnProfile = widget.userId == null || widget.userId == appState.user?.id;
    final userId = widget.userId ?? appState.user?.id ?? '';
    final loaded = _loadedProfile;
    final userName = loaded?['name'] as String? ?? widget.userName ?? appState.user?.name ?? 'Utilizador';
    final userAvatarUrl = loaded?['photoUrl'] as String? ?? widget.userAvatarUrl ?? appState.user?.photoUrl;
    final rawCover = loaded?['coverUrl'] as String?;
    final userCoverUrl = (rawCover != null && rawCover.isNotEmpty)
        ? resolveImageUrl(rawCover)
        : null;
    final bikesList = loaded?['bikes'] as List<dynamic>?;
    final firstBike = bikesList != null && bikesList.isNotEmpty ? bikesList.first as Map<String, dynamic>? : null;
    final bikeModel = firstBike?['model'] as String? ?? widget.userBikeModel ?? appState.bike?.model ?? '';
    final bike = isOwnProfile
        ? appState.bike
        : _bikeFromLoaded(firstBike);

    final userStories = feed.stories.where((s) => s.userId == userId).toList();
    final userPosts = feed.posts.where((p) => p.userId == userId).toList();

    final effectiveAvatarUrl = _avatarPath != null
        ? null
        : (userAvatarUrl != null && userAvatarUrl.isNotEmpty ? userAvatarUrl : null);
    final effectiveAvatarPath = isOwnProfile ? _avatarPath : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              foregroundColor: innerBoxIsScrolled ? null : Colors.white,
              leading: IconButton(
                icon: Icon(
                  LucideIcons.arrowLeft,
                  color: innerBoxIsScrolled ? theme.iconTheme.color : Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: isOwnProfile
                  ? [
                      IconButton(
                        icon: Icon(
                          LucideIcons.settings,
                          color: innerBoxIsScrolled ? theme.iconTheme.color : Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ]
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: _loadingProfile
                    ? const Center(child: CircularProgressIndicator(color: Colors.white70))
                    : _ProfileHeader(
                        handle: _handleFromName(userName),
                        userName: userName,
                        location: 'São Paulo, SP',
                        avatarUrl: effectiveAvatarUrl,
                        avatarPath: effectiveAvatarPath,
                        coverPath: isOwnProfile ? _coverPath : null,
                        coverUrl: userCoverUrl,
                        followersCount: (loaded?['followersCount'] as num?)?.toInt() ?? 0,
                        followingCount: (loaded?['followingCount'] as num?)?.toInt() ?? 0,
                        userId: userId,
                        isOwnProfile: isOwnProfile,
                        onFollowersTap: () => _openFollowList(userId, isFollowers: true),
                        onFollowingTap: () => _openFollowList(userId, isFollowers: false),
                        onCoverTap: _pickCover,
                        onAvatarTap: _pickAvatar,
                        loadingCover: _loadingCover,
                        loadingAvatar: _loadingAvatar,
                        hasPendingFollowRequest: _hasPendingFollowRequest,
                        onSendFollowRequest: _sendFollowRequestFromProfile,
                      ),
              ),
            ),
            if (!isOwnProfile && !_loadingProfile) ...[
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SafeArea(
                    top: false,
                    child: FilledButton(
                      onPressed: _hasPendingFollowRequest ? null : _sendFollowRequestFromProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.racingOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _hasPendingFollowRequest ? 'Solicitação enviada' : 'Solicitar seguir',
                      ),
                    ),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.racingOrange,
                      unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      indicatorColor: AppColors.racingOrange,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        Tab(text: '${userStories.length} Storys'),
                        Tab(text: '${userPosts.length} Momentos'),
                        const Tab(text: 'Garagem'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _StorysTab(stories: userStories),
            _MomentosTab(posts: userPosts),
            _GaragemTab(bike: bike, bikeModel: bikeModel, isOwnProfile: isOwnProfile),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String handle;
  final String userName;
  final String location;
  final String? avatarUrl;
  final String? avatarPath;
  final String? coverPath;
  final String? coverUrl;
  final int followersCount;
  final int followingCount;
  final String? userId;
  final bool isOwnProfile;
  final VoidCallback? onCoverTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onAvatarTap;
  final bool loadingCover;
  final bool loadingAvatar;
  final bool hasPendingFollowRequest;
  final VoidCallback? onSendFollowRequest;

  const _ProfileHeader({
    required this.handle,
    required this.userName,
    required this.location,
    this.avatarUrl,
    this.avatarPath,
    this.coverPath,
    this.coverUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.userId,
    this.isOwnProfile = false,
    this.onCoverTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onAvatarTap,
    this.loadingCover = false,
    this.loadingAvatar = false,
    this.hasPendingFollowRequest = false,
    this.onSendFollowRequest,
  });

  static Widget _defaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D2642),
            Color(0xFF454060),
            Color(0xFF3A3550),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = (avatarUrl != null && avatarUrl!.isNotEmpty) || avatarPath != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        /// Capa
        Positioned.fill(
          child: GestureDetector(
            onTap: isOwnProfile ? onCoverTap : null,
            child: coverPath != null
                ? Image.file(
                    File(coverPath!),
                    fit: BoxFit.cover,
                  )
                : (coverUrl != null && coverUrl!.isNotEmpty)
                    ? ApiImage(
                        url: coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultCover(),
                      )
                    : _defaultCover(),
          ),
        ),
        if (isOwnProfile)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 56,
            child: _CoverEditHint(
              onTap: onCoverTap,
              loading: loadingCover,
              label: coverPath == null ? 'Adicionar capa' : 'Alterar capa',
            ),
          ),
        /// Overlay escuro suave para legibilidade (IgnorePointer para não bloquear toques)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
        /// Conteúdo
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 44, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  handle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 60),
                /// Foto de perfil
                GestureDetector(
                  onTap: isOwnProfile ? onAvatarTap : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: avatarPath != null
                                  ? Image.file(File(avatarPath!), fit: BoxFit.cover)
                                  : (hasAvatar && avatarUrl != null && avatarUrl!.isNotEmpty)
                                      ? ApiImage(url: avatarUrl!, fit: BoxFit.cover)
                                      : Container(
                                          color: const Color(0xFFE8E6F0),
                                          alignment: Alignment.center,
                                          child: Text(
                                            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              color: theme.brightness == Brightness.dark
                                                  ? Colors.white70
                                                  : const Color(0xFF2D2642),
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      ),
                      if (isOwnProfile)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.racingOrange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: loadingAvatar
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CountChip(
                      label: '$followersCount Seguidores',
                      onTap: onFollowersTap,
                    ),
                    const SizedBox(width: 12),
                    _CountChip(
                      label: '$followingCount A seguir',
                      onTap: onFollowingTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverEditHint extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final String label;

  const _CoverEditHint({
    this.onTap,
    this.loading = false,
    this.label = 'Adicionar capa',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.camera, size: 16, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _CountChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StorysTab extends StatelessWidget {
  final List<Story> stories;

  const _StorysTab({required this.stories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stories.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.image,
        title: 'Ainda sem storys',
        subtitle: 'Partilhe o teu primeiro momento na estrada.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.75,
      ),
      itemCount: stories.length,
      itemBuilder: (context, i) {
        final s = stories[i];
        final isAsset = s.mediaUrl.startsWith('assets/');
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryViewScreen(
                  stories: stories,
                  initialIndex: i,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.cardColor,
            ),
            clipBehavior: Clip.antiAlias,
            child: isAsset
                ? Image.asset(s.mediaUrl, fit: BoxFit.cover)
                : ApiImage(url: s.mediaUrl, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _MomentosTab extends StatelessWidget {
  final List<Post> posts;

  const _MomentosTab({required this.posts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (posts.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.sparkles,
        title: 'Ainda sem momentos',
        subtitle: 'As tuas publicações aparecerão aqui.',
      );
    }

    final postsWithImages = posts.where((p) => p.images != null && p.images!.isNotEmpty).toList();
    if (postsWithImages.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.sparkles,
        title: 'Sem fotos ainda',
        subtitle: 'Publica algo com imagem para ver aqui.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: postsWithImages.length,
      itemBuilder: (context, i) {
        final p = postsWithImages[i];
        final img = p.images!.first;
        final isUrl = img.startsWith('http');
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.cardColor,
          ),
          clipBehavior: Clip.antiAlias,
          child: isUrl
              ? ApiImage(url: img, fit: BoxFit.cover)
              : Image.asset(img, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _GaragemTab extends StatelessWidget {
  final Bike? bike;
  final String bikeModel;
  final bool isOwnProfile;

  const _GaragemTab({
    this.bike,
    required this.bikeModel,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!isOwnProfile) {
      return _EmptyState(
        icon: LucideIcons.bike,
        title: 'Garagem privada',
        subtitle: 'Só o dono pode ver a garagem.',
      );
    }

    if (bike == null && bikeModel.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.bike,
        title: 'Ainda sem moto',
        subtitle: 'Adiciona a tua moto na garagem.',
        action: 'Ver garagem',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GarageScreen()),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bike != null) ...[
            _BikeCard(bike: bike!),
            const SizedBox(height: 16),
          ],
          if (bikeModel.isNotEmpty && bike == null)
            Text(
              bikeModel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GarageScreen()),
              );
            },
            icon: const Icon(LucideIcons.bike),
            label: const Text('Ver garagem completa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.racingOrange,
              side: const BorderSide(color: AppColors.racingOrange),
            ),
          ),
        ],
      ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  final Bike bike;

  const _BikeCard({required this.bike});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.racingOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.bike, color: AppColors.racingOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bike.brand} ${bike.model}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      bike.plate,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${bike.currentKm} km',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.racingOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: AppColors.racingOrange.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null && onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.racingOrange,
                  ),
                  child: Text(action!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
