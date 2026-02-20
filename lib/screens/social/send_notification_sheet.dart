import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../models/notification_alert.dart';
import '../../providers/app_state_provider.dart';
import '../../services/notification_alert_service.dart';

/// Sheet em dois passos: 1) Rede ou Comunidade, 2) Tipo de aviso.
class SendNotificationSheet extends StatefulWidget {
  const SendNotificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SendNotificationSheet(),
    );
  }

  @override
  State<SendNotificationSheet> createState() => _SendNotificationSheetState();
}

class _SendNotificationSheetState extends State<SendNotificationSheet> {
  int _step = 0;
  NotificationTarget? _target;
  NotificationAlertType? _alertType;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_step > 0)
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => setState(() {
                      _step = 0;
                      _target = null;
                      _alertType = null;
                    }),
                  ),
                Expanded(
                  child: Text(
                    _step == 0 ? 'Enviar notificação para' : 'Tipo de aviso',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_step > 0) const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 20),
            if (_step == 0) ...[
              _TargetTile(
                icon: LucideIcons.globe,
                label: 'Toda a rede',
                subtitle: 'Todos os utilizadores da rede',
                selected: _target == NotificationTarget.network,
                onTap: () => setState(() => _target = NotificationTarget.network),
              ),
              const SizedBox(height: 8),
              _TargetTile(
                icon: LucideIcons.users,
                label: 'Minha comunidade',
                subtitle: 'Apenas a sua comunidade',
                selected: _target == NotificationTarget.community,
                onTap: () => setState(() => _target = NotificationTarget.community),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _target == null
                    ? null
                    : () => setState(() => _step = 1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.racingOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continuar'),
              ),
            ] else ...[
              ...NotificationAlertType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TargetTile(
                      icon: t.icon,
                      label: t.label,
                      subtitle: null,
                      selected: _alertType == t,
                      onTap: () => setState(() => _alertType = t),
                    ),
                  )),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _alertType == null || _sending
                    ? null
                    : () => _send(theme),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.racingOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_target == NotificationTarget.network
                        ? 'Enviar para a rede'
                        : 'Enviar para a comunidade'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _send(ThemeData theme) async {
    if (_target == null || _alertType == null) return;
    final user = Provider.of<AppStateProvider>(context, listen: false).user;
    if (user == null) return;
    setState(() => _sending = true);
    try {
      await NotificationAlertService.sendAlert(
        target: _target!,
        alertType: _alertType!,
        userId: user.id,
        userName: user.name,
      );
    } catch (_) {
      // ignorar erro; em produção poderia mostrar SnackBar de erro
    }
    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notificação "${_alertType!.label}" enviada para ${_target == NotificationTarget.network ? "a rede" : "a comunidade"}.',
        ),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TargetTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppColors.racingOrange
                  : theme.dividerColor.withOpacity(0.6),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.racingOrange : theme.iconTheme.color,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  LucideIcons.check,
                  color: AppColors.racingOrange,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
