import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/pilot_profile.dart';
import '../../models/community_type.dart';
import '../communities/communities_list_screen.dart';
import '../../widgets/onboarding_form_widgets.dart';
import '../../utils/colors.dart';

class PilotProfileSelectScreen extends StatefulWidget {
  final PilotProfileType? initialSelection;
  /// Se true (piloto de bicicleta), só o cartão Delivery fica ativo.
  final bool onlyDeliveryForBicycle;
  final ValueChanged<PilotProfileType> onContinue;

  const PilotProfileSelectScreen({
    super.key,
    this.initialSelection,
    this.onlyDeliveryForBicycle = false,
    required this.onContinue,
  });

  @override
  State<PilotProfileSelectScreen> createState() =>
      _PilotProfileSelectScreenState();
}

class _PilotProfileSelectScreenState extends State<PilotProfileSelectScreen> {
  PilotProfileType? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.onlyDeliveryForBicycle) {
      _selected = PilotProfileType.delivery;
    } else {
      _selected = widget.initialSelection;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _profileOptions;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Como você usa a moto?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.onlyDeliveryForBicycle
                    ? 'Com bicicleta, o cadastro é para trabalhar com entregas (perfil Delivery).'
                    : 'Escolha o perfil que mais combina com você. Isso personaliza o app e as comunidades.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = _selected == option.type;
                    final isLocked = widget.onlyDeliveryForBicycle &&
                        option.type != PilotProfileType.delivery;
                    return _ProfileCard(
                      option: option,
                      isSelected: isSelected,
                      isDimmed: isLocked,
                      onTap: () {
                        if (isLocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Com bicicleta, use o perfil Delivery para trabalhar com entregas.',
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => _selected = option.type);
                      },
                    );
                  },
                ),
              ),
              if (_selected != null) ...[
                const SizedBox(height: 8),
                _RecommendedCommunitiesPreview(profile: _selected!),
                const SizedBox(height: 10),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: OnboardingPrimaryButton(
                  key: ValueKey(_selected != null),
                  label: _selected == PilotProfileType.delivery
                      ? 'Continuar para cadastro de entregador'
                      : 'Continuar',
                  onPressed: _selected == null
                      ? null
                      : () => widget.onContinue(_selected!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final _PilotProfileOption option;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.option,
    required this.isSelected,
    this.isDimmed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = option.accent;
    final isWork = option.type == PilotProfileType.delivery;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDimmed ? 0.4 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.12) : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accent
                : (isWork
                    ? accent.withValues(alpha: 0.45)
                    : theme.dividerColor.withValues(alpha: 0.35)),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: option.type.heroTag,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(option.icon, color: accent, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                LucideIcons.checkCircle2,
                                size: 20,
                                color: accent,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Badge(
                              label: option.badge,
                              color: accent,
                            ),
                            if (option.secondaryBadge != null)
                              _Badge(
                                label: option.secondaryBadge!,
                                color: accent,
                                outlined: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.8),
                            height: 1.35,
                          ),
                        ),
                        if (option.hint != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            option.hint!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;

  const _Badge({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _PilotProfileOption {
  final PilotProfileType type;
  final String title;
  final String description;
  final String badge;
  final String? secondaryBadge;
  final String? hint;
  final IconData icon;
  final Color accent;

  const _PilotProfileOption({
    required this.type,
    required this.title,
    required this.description,
    required this.badge,
    this.secondaryBadge,
    this.hint,
    required this.icon,
    required this.accent,
  });
}

const List<_PilotProfileOption> _profileOptions = [
  _PilotProfileOption(
    type: PilotProfileType.casual,
    title: 'Casual',
    description:
        'Passeios leves, fins de semana e rolês com amigos. Ideal se a moto é lazer, não trabalho.',
    badge: 'Lazer',
    secondaryBadge: 'Fim de semana',
    icon: LucideIcons.sun,
    accent: AppColors.racingOrange,
  ),
  _PilotProfileOption(
    type: PilotProfileType.diario,
    title: 'Uso diário',
    description:
        'Você usa a moto todo dia para ir ao trabalho, faculdade ou deslocamentos na cidade — sem fazer entregas.',
    badge: 'Urbano',
    secondaryBadge: 'Dia a dia',
    icon: LucideIcons.mapPin,
    accent: AppColors.neonGreen,
  ),
  _PilotProfileOption(
    type: PilotProfileType.racing,
    title: 'Racing / pista',
    description:
        'Foco em performance, track day e adrenalina. Comunidades e conteúdo voltados à pista.',
    badge: 'Pista',
    secondaryBadge: 'Performance',
    icon: LucideIcons.trophy,
    accent: AppColors.alertRed,
  ),
  _PilotProfileOption(
    type: PilotProfileType.delivery,
    title: 'Delivery — quero trabalhar',
    description:
        'Para quem quer receber e fazer corridas de entrega pelo Giro Certo (moto ou bike). Você vai cadastrar documentos e aguardar aprovação.',
    badge: 'Trabalho',
    secondaryBadge: 'Ganhe com entregas',
    hint: 'Escolha esta opção se o seu objetivo é trabalhar como entregador.',
    icon: LucideIcons.package,
    accent: AppColors.statusWarning,
  ),
];

class _RecommendedCommunitiesPreview extends StatelessWidget {
  final PilotProfileType profile;

  const _RecommendedCommunitiesPreview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = switch (profile) {
      PilotProfileType.casual => [CommunityType.lazer, CommunityType.zona],
      PilotProfileType.diario => [CommunityType.zona, CommunityType.manutencao],
      PilotProfileType.racing => [CommunityType.marca, CommunityType.lazer],
      PilotProfileType.delivery => [CommunityType.delivery, CommunityType.zona],
    };
    final subtitle = switch (profile) {
      PilotProfileType.delivery =>
        'Grupos de entregadores e por zona — toque para explorar.',
      PilotProfileType.casual =>
        'Rolês e comunidades da sua região.',
      PilotProfileType.diario =>
        'Zona e manutenção para o dia a dia.',
      PilotProfileType.racing =>
        'Marcas e lazer com foco em performance.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comunidades para o seu perfil',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...suggestions.map(
                (s) => ActionChip(
                  label: Text(s.label),
                  avatar: const Icon(LucideIcons.users, size: 14),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunitiesListScreen(initialType: s),
                    ),
                  ),
                ),
              ),
              ActionChip(
                label: const Text('Ver todas'),
                avatar: const Icon(LucideIcons.list, size: 14),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CommunitiesListScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
