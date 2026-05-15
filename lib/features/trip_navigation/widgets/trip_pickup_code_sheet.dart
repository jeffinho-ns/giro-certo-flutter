import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../utils/colors.dart';
import '../../../utils/delivery_pickup_code.dart';

/// Coleta o codigo de retirada sem revelar o valor esperado ao entregador.
Future<String?> showTripPickupCodeSheet(BuildContext context) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final isDark = theme.brightness == Brightness.dark;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
                isDark ? AppColors.panelDarkLow : AppColors.panelLightLow,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.racingOrange.withValues(alpha: 0.28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.racingOrange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      color: AppColors.racingOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cadeado da loja',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Solicite o codigo de retirada ao lojista. O app nao exibe a resposta; voce precisa confirmar o handoff no balcao.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                autofocus: true,
                maxLength: 16,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    const SizedBox.shrink(),
                decoration: const InputDecoration(
                  labelText: 'Codigo de retirada da loja',
                  hintText: '4 digitos (ex.: 1847) ou codigo antigo GC-...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final code = DeliveryPickupCode.normalize(controller.text);
                        if (!DeliveryPickupCode.isValidFormat(code)) return;
                        Navigator.of(sheetContext).pop(code);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coletar e iniciar entrega'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
