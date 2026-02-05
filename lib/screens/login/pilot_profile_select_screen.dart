import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/pilot_profile.dart';
import '../../widgets/onboarding_form_widgets.dart';
import '../../utils/colors.dart';

class PilotProfileSelectScreen extends StatefulWidget {
  final PilotProfileType? initialSelection;
  final ValueChanged<PilotProfileType> onContinue;

  const PilotProfileSelectScreen({
    super.key,
    this.initialSelection,
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
    _selected = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _profileOptions;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfil do Piloto',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha como voce usa sua moto no dia a dia.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = _selected == option.type;
                    return _ProfileCard(
                      option: option,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selected = option.type);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: OnboardingPrimaryButton(
                  key: ValueKey(_selected != null),
                  label: 'Continuar',
                  onPressed:
                      _selected == null ? null : () => widget.onContinue(_selected!),
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
  final VoidCallback onTap;

  const _ProfileCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = option.accent;

    return AnimatedScale(
      scale: isSelected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 240),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withOpacity(0.15)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : theme.dividerColor.withOpacity(0.35),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: option.type.heroTag,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(option.icon, color: accent, size: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    option.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          option.badge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: isSelected ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          LucideIcons.checkCircle,
                          size: 18,
                          color: accent,
                        ),
                      ),
                    ],
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

class _PilotProfileOption {
  final PilotProfileType type;
  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final Color accent;

  const _PilotProfileOption({
    required this.type,
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.accent,
  });
}

const List<_PilotProfileOption> _profileOptions = [
  _PilotProfileOption(
    type: PilotProfileType.casual,
    title: 'Casual',
    description: 'Passeios leves e curtos nos fins de semana.',
    badge: 'Fim de Semana',
    icon: LucideIcons.sun,
    accent: AppColors.racingOrange,
  ),
  _PilotProfileOption(
    type: PilotProfileType.diario,
    title: 'Diario',
    description: 'Uso diario e deslocamentos urbanos.',
    badge: 'Urbano',
    icon: LucideIcons.mapPin,
    accent: AppColors.neonGreen,
  ),
  _PilotProfileOption(
    type: PilotProfileType.racing,
    title: 'Racing',
    description: 'Performance, pista e adrenalina.',
    badge: 'Pista',
    icon: LucideIcons.trophy,
    accent: AppColors.alertRed,
  ),
  _PilotProfileOption(
    type: PilotProfileType.delivery,
    title: 'Delivery',
    description: 'Rotina profissional com foco em entregas.',
    badge: 'Trabalho',
    icon: LucideIcons.package,
    accent: AppColors.statusWarning,
  ),
];
