import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/motorcycle_model.dart';
import '../../models/pilot_profile.dart';
import '../../utils/colors.dart';
import '../../widgets/onboarding_form_widgets.dart';

class GarageSetupDetails {
  final String nickname;
  final String ridingStyle;
  final List<String> accessories;
  final String? nextUpgrade;
  final String? colorLabel;

  const GarageSetupDetails({
    required this.nickname,
    required this.ridingStyle,
    required this.accessories,
    this.nextUpgrade,
    this.colorLabel,
  });
}

class GarageSetupDetailScreen extends StatefulWidget {
  final MotorcycleModel motorcycle;
  final String? motorcycleImagePath;
  final PilotProfileType pilotType;
  final ValueChanged<GarageSetupDetails> onFinish;
  final VoidCallback? onBack;

  const GarageSetupDetailScreen({
    super.key,
    required this.motorcycle,
    required this.pilotType,
    required this.onFinish,
    this.motorcycleImagePath,
    this.onBack,
  });

  @override
  State<GarageSetupDetailScreen> createState() =>
      _GarageSetupDetailScreenState();
}

class _GarageSetupDetailScreenState extends State<GarageSetupDetailScreen> {
  final _nicknameController = TextEditingController();
  final _nextUpgradeController = TextEditingController();
  final Set<String> _selectedAccessories = {};

  String _selectedRidingStyle = 'Urbano';
  String? _selectedColorLabel;
  bool _isSubmitting = false;

  static const List<String> _ridingStyles = [
    'Urbano',
    'Estrada',
    'Touring',
    'Esportivo',
    'Custom',
  ];

  static const List<String> _accessoryOptions = [
    'Bau',
    'Mochila',
    'Protetor de motor',
    'Suporte celular',
    'Escape esportivo',
    'Iluminacao LED',
  ];

  @override
  void initState() {
    super.initState();
    _selectedColorLabel = widget.motorcycle.availableColors.isNotEmpty
        ? widget.motorcycle.availableColors.first
        : 'red';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nextUpgradeController.dispose();
    super.dispose();
  }

  Color _colorFromLabel(String label, ThemeData theme) {
    final normalized = label.toLowerCase().trim();
    switch (normalized) {
      case 'black':
      case 'preto':
        return theme.brightness == Brightness.dark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
      case 'white':
      case 'branco':
        return theme.brightness == Brightness.dark
            ? AppColors.lightSurface
            : AppColors.lightBackground;
      case 'blue':
      case 'azul':
        return const Color(0xFF5C9FD4);
      case 'green':
      case 'verde':
        return AppColors.neonGreen;
      case 'orange':
      case 'laranja':
      case 'red':
      case 'vermelho':
      default:
        return AppColors.racingOrange;
    }
  }

  Color _resolveAccentColor(ThemeData theme) {
    return _colorFromLabel(_selectedColorLabel ?? 'red', theme);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await _showApprovedFeedback();
    if (!mounted) return;
    widget.onFinish(
      GarageSetupDetails(
        nickname: _nicknameController.text.trim().isEmpty
            ? widget.motorcycle.model
            : _nicknameController.text.trim(),
        ridingStyle: _selectedRidingStyle,
        accessories: _selectedAccessories.toList(),
        nextUpgrade: _nextUpgradeController.text.trim().isEmpty
            ? null
            : _nextUpgradeController.text.trim(),
        colorLabel: _selectedColorLabel,
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  Future<void> _showApprovedFeedback() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _StatusDialog(
        title: 'Garagem confirmada',
        status: 'APPROVED',
        icon: LucideIcons.checkCircle,
        iconColor: AppColors.statusOk,
        subtitle: 'Sua garagem premium esta ativa.',
      ),
    );
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  IconData _iconForPilotType(PilotProfileType type) {
    switch (type) {
      case PilotProfileType.casual:
        return LucideIcons.sun;
      case PilotProfileType.diario:
        return LucideIcons.mapPin;
      case PilotProfileType.racing:
        return LucideIcons.trophy;
      case PilotProfileType.delivery:
        return LucideIcons.package;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _resolveAccentColor(theme);
    final imagePath =
        widget.motorcycleImagePath ?? widget.motorcycle.modelImagePath;
    final showUpgradeField = widget.pilotType == PilotProfileType.casual ||
        widget.pilotType == PilotProfileType.racing;

    return WillPopScope(
      onWillPop: () async {
        if (widget.onBack != null) {
          widget.onBack!();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: widget.onBack ??
                  () => Navigator.of(context).maybePop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('${widget.motorcycle.brand} ${widget.motorcycle.model}'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/moto-black.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          accent.withOpacity(0.25),
                          theme.scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Hero(
                      tag: widget.pilotType.heroTag,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accent.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _iconForPilotType(widget.pilotType),
                          color: accent,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Garagem Premium',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personalize sua moto e deixe tudo pronto para rodar.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OnboardingSectionCard(
                    title: 'Cor predominante',
                    subtitle: 'Use a cor para personalizar sua garagem.',
                    icon: LucideIcons.palette,
                    accentColor: accent,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: widget.motorcycle.availableColors.map((color) {
                        final colorValue = _colorFromLabel(color, theme);
                        final isSelected = _selectedColorLabel == color;
                        return ChoiceChip(
                          label: Text(color),
                          selected: isSelected,
                          selectedColor: colorValue.withOpacity(0.2),
                          avatar: CircleAvatar(
                            radius: 6,
                            backgroundColor: colorValue,
                          ),
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected ? colorValue : null,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedColorLabel = color);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OnboardingSectionCard(
                    title: 'Nome da moto',
                    subtitle: 'De um apelido com a sua cara.',
                    icon: LucideIcons.sparkles,
                    accentColor: accent,
                    child: OnboardingTextField(
                      label: 'Apelido',
                      hint: 'Minha Nave',
                      icon: LucideIcons.bike,
                      controller: _nicknameController,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OnboardingSectionCard(
                    title: 'Estilo de pilotagem',
                    subtitle: 'Escolha o estilo que mais combina com voce.',
                    icon: LucideIcons.mapPin,
                    accentColor: accent,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: _ridingStyles.map((style) {
                        final isSelected = _selectedRidingStyle == style;
                        return ChoiceChip(
                          label: Text(style),
                          selected: isSelected,
                          selectedColor: accent.withOpacity(0.15),
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected ? accent : null,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedRidingStyle = style);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OnboardingSectionCard(
                    title: 'Acessorios instalados',
                    subtitle: 'Selecione o que ja esta na moto.',
                    icon: LucideIcons.wrench,
                    accentColor: accent,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: _accessoryOptions.map((item) {
                        final selected = _selectedAccessories.contains(item);
                        return FilterChip(
                          label: Text(item),
                          selected: selected,
                          selectedColor: accent.withOpacity(0.18),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedAccessories.add(item);
                              } else {
                                _selectedAccessories.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  if (showUpgradeField) ...[
                    const SizedBox(height: 16),
                    OnboardingSectionCard(
                      title: 'Proximo upgrade',
                      subtitle: 'O que voce quer adicionar em seguida?',
                      icon: LucideIcons.sparkles,
                      accentColor: accent,
                      child: OnboardingTextField(
                        label: 'Upgrade desejado',
                        hint: 'Ex: Escape esportivo',
                        icon: LucideIcons.sparkles,
                        controller: _nextUpgradeController,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OnboardingPrimaryButton(
                    label: 'Finalizar Garagem',
                    icon: LucideIcons.checkCircle,
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
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
}

class _StatusDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color iconColor;

  const _StatusDialog({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Status: $status',
              style: theme.textTheme.labelSmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
