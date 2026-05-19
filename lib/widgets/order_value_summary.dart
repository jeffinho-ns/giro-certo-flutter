import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Resumo: valor dos itens + frete + total (cliente paga itens+frete na cobrança).
class OrderValueSummary extends StatelessWidget {
  const OrderValueSummary({
    super.key,
    required this.orderValue,
    required this.deliveryFee,
    this.compact = false,
    this.highlightTotal = true,
  });

  final double orderValue;
  final double deliveryFee;
  final bool compact;
  final bool highlightTotal;

  double get total => orderValue + deliveryFee;

  static String formatBrl(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlightTotal)
            Text(
              formatBrl(total),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.neonGreen,
              ),
            ),
          Text(
            'Pedido ${formatBrl(orderValue)}',
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
          Text(
            'Frete ${formatBrl(deliveryFee)}',
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          _row(theme, 'Valor do pedido (itens)', formatBrl(orderValue), muted),
          const SizedBox(height: 8),
          _row(theme, 'Frete', formatBrl(deliveryFee), muted),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _row(
            theme,
            'Total ao cliente',
            formatBrl(total),
            null,
            valueStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.neonGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value,
    Color? muted, {
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
