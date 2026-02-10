import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/colors.dart';
import '../../providers/drawer_provider.dart';
import '../sidebars/profile_sidebar.dart';
import '../../widgets/modern_header.dart';
import '../../services/api_service.dart';
import 'story_view_screen.dart';

class SocialHomeScreen extends StatefulWidget {
  const SocialHomeScreen({super.key});

  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> {
  final List<Map<String, String>> _stories = [
    {'name': 'Abdul', 'image': 'assets/images/user-1.png', 'storyImage': 'assets/images/prev-story-1.png'},
    {'name': 'Chris', 'image': 'assets/images/user-2.png', 'storyImage': 'assets/images/prev-story-2.png'},
    {'name': 'General', 'image': 'assets/images/user-3.png', 'storyImage': 'assets/images/prev-story-3.png'},
    {'name': 'Ojogbon', 'image': 'assets/images/user-1.png', 'storyImage': 'assets/images/prev-story-1.png'},
    {'name': 'Oyin Dolapo', 'image': 'assets/images/user-2.png', 'storyImage': 'assets/images/prev-story-2.png'},
    {'name': 'Rider 1', 'image': 'assets/images/user-3.png', 'storyImage': 'assets/images/prev-story-3.png'},
    {'name': 'Rider 2', 'image': 'assets/images/user-1.png', 'storyImage': 'assets/images/prev-story-1.png'},
    {'name': 'Rider 3', 'image': 'assets/images/user-2.png', 'storyImage': 'assets/images/prev-story-2.png'},
  ];

  final List<Map<String, String>> _posts = [
    {
      'name': 'Oyin Dolapo',
      'userImage': 'assets/images/user-post-1.png',
      'time': '1hr ago',
      'text': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pharetra',
      'postImage': 'assets/images/post-1.png',
    },
    {
      'name': 'Abdul Quayyum',
      'userImage': 'assets/images/user-1.png',
      'time': '2hr ago',
      'text': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pharetra',
      'postImage': 'assets/images/post-1.png',
    },
    {
      'name': 'Chris Rider',
      'userImage': 'assets/images/user-2.png',
      'time': '3hr ago',
      'text': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pharetra',
      'postImage': 'assets/images/post-1.png',
    },
    {
      'name': 'General Flow',
      'userImage': 'assets/images/user-3.png',
      'time': '4hr ago',
      'text': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pharetra',
      'postImage': 'assets/images/post-1.png',
    },
  ];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
      drawerProvider.setScaffoldKey(_scaffoldKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Stack(
          children: [
            ModernHeader(
              title: '',
              transparentOverMap: false,
              hideClockAndKm: true,
            ),
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(LucideIcons.bell),
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const _NotificationsFullSheet(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      endDrawer: const ProfileSidebar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              // Barra de busca compacta
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 18,
                      color: theme.iconTheme.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Procurar...',
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stories maiores (70x110)
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: theme.cardColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                LucideIcons.plus,
                                size: 32,
                                color: AppColors.racingOrange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Publicar',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final s = _stories[index - 1];
                    return Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StoryViewScreen(
                                initialIndex: index - 1,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.racingOrange,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  s['storyImage'] ?? 'assets/images/prev-story-1.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: theme.cardColor,
                                      child: const Icon(LucideIcons.image),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 90,
                              child: Text(
                                s['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Posts
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final p = _posts[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: theme.cardColor,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: AssetImage(
                                  p['userImage'] ?? 'assets/images/user-post-1.png',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['name'] ?? '',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      p['time'] ?? '',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.moreHorizontal),
                                iconSize: 20,
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p['text'] ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              p['postImage'] ?? 'assets/images/post-1.png',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: theme.dividerColor,
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.image,
                                      size: 48,
                                      color: theme.iconTheme.color?.withOpacity(0.4),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(
                                    'assets/images/Heart.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.grey,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text('247', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                              const SizedBox(width: 24),
                              GestureDetector(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(
                                    'assets/images/Chat.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.grey,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text('57', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.scaffoldBackgroundColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(LucideIcons.compass), label: ''),
          BottomNavigationBarItem(icon: Icon(LucideIcons.plusCircle), label: ''),
          BottomNavigationBarItem(icon: Icon(LucideIcons.messageSquare), label: ''),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: ''),
        ],
        currentIndex: 0,
        onTap: (i) {},
      ),
    );
  }
}

class _NotificationsFullSheet extends StatelessWidget {
  const _NotificationsFullSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Notificações',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: ApiService.getAlerts(limit: 50),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final alerts = snapshot.data!;
                    if (alerts.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma notificação',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: alerts.length,
                      itemBuilder: (context, i) {
                        final a = alerts[i];
                        final title = a['title'] as String? ?? 'Alerta';
                        final body = a['body'] as String?;
                        return ListTile(
                          title: Text(title),
                          subtitle: body != null ? Text(body) : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
