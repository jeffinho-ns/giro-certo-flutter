import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/pilot_profile.dart';
import '../../utils/colors.dart';
import '../../widgets/onboarding_form_widgets.dart';

class DeliveryRegistrationDetails {
  final String documentId;
  final List<String> equipments;

  const DeliveryRegistrationDetails({
    required this.documentId,
    required this.equipments,
  });
}

class DeliveryRegistrationScreen extends StatefulWidget {
  final PilotProfileType pilotType;
  final ValueChanged<DeliveryRegistrationDetails> onSubmit;
  final VoidCallback? onBack;

  const DeliveryRegistrationScreen({
    super.key,
    required this.pilotType,
    required this.onSubmit,
    this.onBack,
  });

  @override
  State<DeliveryRegistrationScreen> createState() =>
      _DeliveryRegistrationScreenState();
}

class _DeliveryRegistrationScreenState extends State<DeliveryRegistrationScreen> {
  final _documentController = TextEditingController();
  final Set<String> _selectedEquipments = {};
  bool _isSubmitting = false;

  static const List<String> _equipmentOptions = [
    'Bau',
    'Mochila',
    'Bau termico',
    'Suporte celular',
    'Capa de chuva',
  ];

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await _showPendingFeedback();
    if (!mounted) return;
    widget.onSubmit(
      DeliveryRegistrationDetails(
        documentId: _documentController.text.trim(),
        equipments: _selectedEquipments.toList(),
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  Future<void> _showPendingFeedback() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _StatusDialog(
        title: 'Perfil em analise',
        status: 'PENDING',
        subtitle: 'Seus documentos serao avaliados em breve.',
        icon: LucideIcons.clock,
        iconColor: AppColors.statusWarning,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1000));
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
    final accent = theme.colorScheme.primary;

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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: widget.onBack ??
                          () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Hero(
                      tag: widget.pilotType.heroTag,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconForPilotType(widget.pilotType),
                          size: 20,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Cadastro Delivery',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete as informacoes para validar seu perfil profissional.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                OnboardingSectionCard(
                  title: 'Documento do piloto',
                  subtitle: 'Informe CPF ou CNH para validacao.',
                  icon: LucideIcons.idCard,
                  accentColor: accent,
                  child: OnboardingTextField(
                    label: 'CPF/CNH',
                    hint: '000.000.000-00',
                    icon: LucideIcons.fileText,
                    controller: _documentController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 16),
                OnboardingSectionCard(
                  title: 'Upload de documentos',
                  subtitle: 'Envie fotos da CNH e do CRLV.',
                  icon: LucideIcons.uploadCloud,
                  accentColor: accent,
                  child: Column(
                    children: [
                      _DocumentUploadCard(
                        label: 'Foto da CNH',
                        icon: LucideIcons.camera,
                        onTap: () => _showUploadHint(context),
                      ),
                      const SizedBox(height: 12),
                      _DocumentUploadCard(
                        label: 'Foto do CRLV',
                        icon: LucideIcons.fileImage,
                        onTap: () => _showUploadHint(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OnboardingSectionCard(
                  title: 'Equipamentos',
                  subtitle: 'Selecione o que voce usa nas entregas.',
                  icon: LucideIcons.package,
                  accentColor: accent,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: _equipmentOptions.map((item) {
                      final selected = _selectedEquipments.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: selected,
                        selectedColor: accent.withOpacity(0.18),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedEquipments.add(item);
                            } else {
                              _selectedEquipments.remove(item);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                OnboardingPrimaryButton(
                  label: 'Enviar para Analise',
                  icon: LucideIcons.send,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUploadHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload em breve.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DocumentUploadCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                LucideIcons.upload,
                size: 18,
                color: accent,
              ),
            ],
          ),
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
