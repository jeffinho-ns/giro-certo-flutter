import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../models/delivery_order.dart';
import '../../../utils/colors.dart';
import '../../../utils/delivery_proof_pin.dart';

class TripDeliveryProofPanel extends StatefulWidget {
  const TripDeliveryProofPanel({
    super.key,
    required this.order,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final DeliveryOrder order;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function(String pin) onSubmit;

  @override
  State<TripDeliveryProofPanel> createState() => _TripDeliveryProofPanelState();
}

class _TripDeliveryProofPanelState extends State<TripDeliveryProofPanel> {
  final TextEditingController _controller = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPinChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onPinChanged() {
    final canSubmit =
        DeliveryProofPin.isValidFormat(DeliveryProofPin.normalize(_controller.text));
    if (canSubmit != _canSubmit) {
      setState(() => _canSubmit = canSubmit);
    }
  }

  Future<void> _submit() async {
    if (widget.isLoading || !_canSubmit) return;
    final pin = DeliveryProofPin.normalize(_controller.text);
    await widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      color: AppColors.neonGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Prova de entrega',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'A navegacao foi encerrada. Solicite ao cliente os 4 ultimos digitos do telefone cadastrado no pedido para finalizar a corrida.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.recipientName ?? 'Cliente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.order.deliveryAddress,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: DeliveryProofPin.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  labelText: 'PIN do cliente',
                  hintText: '0000',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.alertRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: widget.isLoading || !_canSubmit ? null : () => unawaited(_submit()),
                  icon: widget.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.checkCircle),
                  label: Text(
                    widget.isLoading ? 'Validando PIN...' : 'Finalizar corrida',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
