import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../models/achievement.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';

/// Catálogo de conquistas: já desbloqueadas + próximas a desbloquear.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _unlocked = const [];
  bool _loading = true;

  /// Catálogo "aspiracional" — usado para mostrar conquistas ainda não
  /// desbloqueadas. Idealmente vem do backend; até lá usamos um catálogo
  /// estático razoável para todos os perfis.
  static const List<Achievement> _catalog = [
    Achievement(
      id: 'first_ride',
      name: 'Primeira pedalada',
      description: 'Complete sua primeira rota com o Giro Certo.',
    ),
    Achievement(
      id: 'distance_100',
      name: 'Centurião',
      description: 'Rode 100 km acumulados no app.',
    ),
    Achievement(
      id: 'distance_1000',
      name: 'Maratonista',
      description: 'Rode 1.000 km acumulados.',
    ),
    Achievement(
      id: 'maintenance_first',
      name: 'Cuidador',
      description: 'Registre sua primeira manutenção.',
    ),
    Achievement(
      id: 'community_member',
      name: 'Tribo',
      description: 'Entre em pelo menos uma comunidade.',
    ),
    Achievement(
      id: 'moment_first',
      name: 'Cinegrafista',
      description: 'Publique seu primeiro Momento.',
    ),
    Achievement(
      id: 'event_first',
      name: 'Encontrista',
      description: 'Confirme presença em um evento.',
    ),
    Achievement(
      id: 'delivery_10',
      name: 'Entregador Bronze',
      description: 'Conclua 10 entregas (perfil Delivery).',
    ),
    Achievement(
      id: 'delivery_100',
      name: 'Entregador Prata',
      description: 'Conclua 100 entregas.',
    ),
    Achievement(
      id: 'partner_voucher',
      name: 'Caçador de Ofertas',
      description: 'Resgate seu primeiro voucher com parceiros.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final id = appState.user?.id;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final list = await ApiService.getAchievements(id);
      if (!mounted) return;
      setState(() {
        _unlocked = list.map(Achievement.fromJson).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedIds = _unlocked.map((a) => a.id).toSet();
    final locked = _catalog
        .where((c) => !unlockedIds.contains(c.id))
        .toList();
    final progress = _catalog.isEmpty
        ? 0.0
        : _unlocked.length / _catalog.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Conquistas',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildSummary(theme, progress),
                          const SizedBox(height: 20),
                          if (_unlocked.isNotEmpty) ...[
                            _sectionTitle(theme, 'Desbloqueadas',
                                _unlocked.length),
                            const SizedBox(height: 8),
                            ..._unlocked.map((a) =>
                                _AchievementTile(a, unlocked: true)),
                            const SizedBox(height: 16),
                          ],
                          _sectionTitle(theme, 'A desbloquear', locked.length),
                          const SizedBox(height: 8),
                          ...locked.map((a) =>
                              _AchievementTile(a, unlocked: false)),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.racingOrange.withOpacity(0.18),
            AppColors.racingOrangeDark.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.racingOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor:
                      AppColors.racingOrange.withOpacity(0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.racingOrange),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu progresso',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_unlocked.length} de ${_catalog.length} conquistas desbloqueadas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text, int count) {
    return Row(
      children: [
        Text(
          text,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.racingOrange.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppColors.racingOrange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementTile(this.achievement, {required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = unlocked
        ? AppColors.racingOrange
        : theme.textTheme.bodyMedium?.color?.withOpacity(0.4) ?? Colors.grey;
    final formattedDate = achievement.unlockedAt != null
        ? DateFormat('dd/MM/yyyy', 'pt_BR').format(achievement.unlockedAt!)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppColors.racingOrange.withOpacity(0.35)
                : theme.dividerColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked ? LucideIcons.trophy : LucideIcons.lock,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: unlocked ? null : color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.7),
                    ),
                  ),
                  if (formattedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Desbloqueada em $formattedDate',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.racingOrange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
