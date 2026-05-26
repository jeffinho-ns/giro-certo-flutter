import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/community.dart';
import '../../models/community_type.dart';
import '../../providers/app_state_provider.dart';
import '../../services/community_service.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../social/create_community_modal.dart';
import 'community_detail_screen.dart';

class CommunitiesListScreen extends StatefulWidget {
  const CommunitiesListScreen({super.key});

  @override
  State<CommunitiesListScreen> createState() => _CommunitiesListScreenState();
}

class _CommunitiesListScreenState extends State<CommunitiesListScreen> {
  List<Community> _all = const [];
  bool _loading = true;
  String _query = '';
  CommunityType? _typeFilter;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    setState(() => _loading = true);
    try {
      final list = await CommunityService.getCommunities(
        userId: appState.user?.id,
      );
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateCommunityModal(),
    );
    if (result != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _all.where((c) {
      final matchesQuery = _query.trim().isEmpty ||
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.description.toLowerCase().contains(_query.toLowerCase());
      final matchesType =
          _typeFilter == null || c.type == _typeFilter;
      return matchesQuery && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Comunidades',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Procurar comunidade...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('Todas', _typeFilter == null,
                      onTap: () => setState(() => _typeFilter = null)),
                  for (final t in CommunityType.values)
                    _chip(t.label, _typeFilter == t,
                        onTap: () => setState(() => _typeFilter = t)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? _empty(theme)
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _CommunityTile(community: filtered[i],
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CommunityDetailScreen(
                                        community: filtered[i],
                                      ),
                                    ),
                                  );
                                }),
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.racingOrange,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Nova comunidade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _empty(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(LucideIcons.users,
            size: 48,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Ainda não há comunidades para mostrar.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Crie a sua e convide outros motociclistas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.racingOrange.withOpacity(0.2),
        labelStyle: TextStyle(
          color: selected ? AppColors.racingOrange : null,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final Community community;
  final VoidCallback onTap;

  const _CommunityTile({required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.racingOrange.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.users,
                    color: AppColors.racingOrange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      community.description.isEmpty
                          ? 'Sem descrição'
                          : community.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.user,
                            size: 12,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${community.memberCount} membros',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.racingOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            community.type.label,
                            style: TextStyle(
                              color: AppColors.racingOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 18,
                  color: theme.iconTheme.color?.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
