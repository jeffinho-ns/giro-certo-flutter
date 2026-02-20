import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import 'profile_page.dart';

/// Tela de busca de utilizadores por @handle ou nome.
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  String _query = '';
  final Set<String> _pendingRequestTargetIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadSentRequestIds();
    });
  }

  Future<void> _loadSentRequestIds() async {
    final ids = await ApiService.getSentFollowRequestTargetIds();
    if (mounted) setState(() => _pendingRequestTargetIds.addAll(ids));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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

  Future<void> _search(String q) async {
    final trimmed = q.trim().replaceFirst(RegExp(r'^@'), '');
    if (trimmed.isEmpty) {
      setState(() {
        _query = q;
        _users = [];
      });
      return;
    }

    setState(() {
      _query = q;
      _loading = true;
    });

    try {
      final list = await ApiService.searchUsers(trimmed);
      if (mounted) {
        setState(() {
          _users = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _users = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendFollowRequest(String userId) async {
    if (_pendingRequestTargetIds.contains(userId)) return;
    setState(() => _pendingRequestTargetIds.add(userId));
    final success = await ApiService.sendFollowRequest(userId);
    if (!success && mounted) {
      setState(() => _pendingRequestTargetIds.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final currentUserId = appState.user?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Procurar utilizadores'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Procurar @utilizadores ou nome...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _search,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _query.trim().isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.search, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Escreve @ ou nome para procurar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum utilizador encontrado',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final u = _users[i];
                        final id = u['id'] as String? ?? '';
                        final name = u['name'] as String? ?? 'Utilizador';
                        final photoUrl = u['photoUrl'] as String?;
                        final isOwn = id == currentUserId;

                        final hasPending = _pendingRequestTargetIds.contains(id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.racingOrange.withOpacity(0.2),
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: AppColors.racingOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(_handleFromName(name)),
                          trailing: isOwn
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProfilePage(
                                              userId: id,
                                              userName: name,
                                              userAvatarUrl: photoUrl,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Ver perfil'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: hasPending ? null : () => _sendFollowRequest(id),
                                      child: Text(
                                        hasPending ? 'Solicitação enviada' : 'Solicitar seguir',
                                        style: TextStyle(
                                          color: hasPending
                                              ? theme.textTheme.bodySmall?.color
                                              : AppColors.racingOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(
                                  userId: id,
                                  userName: name,
                                  userAvatarUrl: photoUrl,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
