import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/rider_ranking_entry.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/api_service.dart';
import '../../services/delivery_migration_flow.dart';
import '../../utils/colors.dart';
import '../../widgets/api_image.dart';
import '../../widgets/modern_header.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<RiderRankingEntry> _entries = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService.getDeliveryRanking(limit: 30);
      final entries = raw
          .asMap()
          .entries
          .map((e) => RiderRankingEntry.fromJson(e.value, e.key))
          .toList();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar o ranking.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = Provider.of<AppStateProvider>(context);
    final canSwitch = DeliveryMigrationFlow.canSwitch(app);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          ModernHeader(
            title: 'Ranking de entregadores',
            showBackButton: true,
            onBackPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).maybePop();
                return;
              }
              Provider.of<NavigationProvider>(context, listen: false)
                  .navigateTo(2);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Icon(LucideIcons.cloudOff,
                                size: 48, color: AppColors.statusWarning),
                            const SizedBox(height: 12),
                            Center(child: Text(_error!, textAlign: TextAlign.center)),
                            const SizedBox(height: 16),
                            Center(
                              child: FilledButton(
                                onPressed: _load,
                                child: const Text('Tentar novamente'),
                              ),
                            ),
                          ],
                        )
                      : _entries.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                const SizedBox(height: 64),
                                Icon(
                                  LucideIcons.trophy,
                                  size: 56,
                                  color: theme.iconTheme.color
                                      ?.withValues(alpha: 0.35),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ainda não há entregadores no ranking.',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'O ranking usa corridas realmente concluídas. '
                                  'Quando houver entregas, os primeiros aparecem aqui.',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                if (canSwitch) ...[
                                  const SizedBox(height: 20),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        DeliveryMigrationFlow.start(context),
                                    icon: const Icon(LucideIcons.package),
                                    label: const Text(
                                      'Quero trabalhar com entregas',
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              itemCount: _entries.length + (canSwitch ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (canSwitch && index == 0) {
                                  return _buildJoinBanner(theme);
                                }
                                final rankIndex =
                                    canSwitch ? index - 1 : index;
                                return _buildRiderCard(
                                  _entries[rankIndex],
                                  rankIndex + 1,
                                  theme,
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.statusWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => DeliveryMigrationFlow.start(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(LucideIcons.package, color: AppColors.statusWarning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Complete corridas para entrar neste ranking.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiderCard(
    RiderRankingEntry entry,
    int rank,
    ThemeData theme,
  ) {
    final isTopRank = rank <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isTopRank
            ? AppColors.racingOrange.withValues(alpha: 0.10)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTopRank
              ? AppColors.racingOrange.withValues(alpha: 0.4)
              : theme.dividerColor,
          width: isTopRank ? 2 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isTopRank
                    ? AppColors.racingOrange
                    : theme.cardColor,
                shape: BoxShape.circle,
                border: isTopRank
                    ? null
                    : Border.all(color: theme.dividerColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: isTopRank
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.racingOrange.withValues(alpha: 0.15),
              child: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: ApiImage(
                        url: entry.photoUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(LucideIcons.user, color: AppColors.racingOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.completedCount} entregas concluídas',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (entry.rating != null)
              Row(
                children: [
                  const Icon(
                    LucideIcons.star,
                    size: 16,
                    color: AppColors.racingOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
