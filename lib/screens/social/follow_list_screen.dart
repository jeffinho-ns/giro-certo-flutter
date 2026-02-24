import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/colors.dart';
import '../../utils/image_url.dart';
import '../../widgets/api_image.dart';
import '../../services/api_service.dart';
import 'user_profile_screen.dart';

/// Lista de seguidores ou de quem o utilizador segue.
class FollowListScreen extends StatefulWidget {
  final String userId;
  final String title;
  final bool isFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.isFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = widget.isFollowers
          ? await ApiService.getFollowers(widget.userId)
          : await ApiService.getFollowing(widget.userId);
      if (mounted) setState(() {
        _list = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.racingOrange))
          : RefreshIndicator(
              onRefresh: _load,
              child: _list.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: Center(
                          child: Text(
                            widget.isFollowers ? 'Sem seguidores' : 'Não segue ninguém',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _list.length,
                      itemBuilder: (context, i) {
                        final u = _list[i];
                        final id = u['id'] as String? ?? '';
                        final name = u['name'] as String? ?? 'Utilizador';
                        final photoUrl = resolveImageUrl(u['photoUrl'] as String?);
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.racingOrange.withOpacity(0.2),
                            child: photoUrl.isNotEmpty
                                ? ClipOval(
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: ApiImage(url: photoUrl, fit: BoxFit.cover),
                                    ),
                                  )
                                : Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.racingOrange,
                                    ),
                                  ),
                          ),
                          title: Text(name),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                  userId: id,
                                  userName: name,
                                  userAvatarUrl: photoUrl.isNotEmpty ? photoUrl : null,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
