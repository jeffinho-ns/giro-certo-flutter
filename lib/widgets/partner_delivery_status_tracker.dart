import 'package:flutter/material.dart';

import '../models/delivery_order.dart';

/// Passos visuais do fluxo na perspetiva do lojista (tempo real).
class PartnerDeliveryStatusTracker extends StatelessWidget {
  const PartnerDeliveryStatusTracker({
    super.key,
    required this.status,
    this.compact = true,
  });

  final DeliveryStatus status;
  final bool compact;

  static int stepIndex(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.awaitingDispatch:
        return 0;
      case DeliveryStatus.pending:
        return 1;
      case DeliveryStatus.accepted:
        return 2;
      case DeliveryStatus.arrivedAtStore:
        return 3;
      case DeliveryStatus.inTransit:
      case DeliveryStatus.inProgress:
        return 4;
      case DeliveryStatus.arrivedAtDestination:
        return 5;
      case DeliveryStatus.completed:
        return 6;
      case DeliveryStatus.cancelled:
        return -1;
    }
  }

  static String shortTitle(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.awaitingDispatch:
        return 'Na loja — confirme o envio';
      case DeliveryStatus.pending:
        return 'A procurar motociclista';
      case DeliveryStatus.accepted:
        return 'Motociclista a caminho da loja';
      case DeliveryStatus.arrivedAtStore:
        return 'Motociclista na loja — retirada';
      case DeliveryStatus.inTransit:
      case DeliveryStatus.inProgress:
        return 'A caminho do cliente';
      case DeliveryStatus.arrivedAtDestination:
        return 'No cliente — confirmação final';
      case DeliveryStatus.completed:
        return 'Entrega concluída';
      case DeliveryStatus.cancelled:
        return 'Pedido cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (status == DeliveryStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, size: 18, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                shortTitle(status),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final idx = stepIndex(status);
    const labels = [
      'Loja',
      'Busca',
      'Vem aí',
      'Retira',
      'Cliente',
      'No local',
      'OK',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            shortTitle(status),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        if (!compact) const SizedBox(height: 8),
        if (!compact)
          Text(
            'Atualizado em tempo real quando o motociclista avança a etapa.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72),
            ),
          ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(labels.length, (i) {
              final completedAll = status == DeliveryStatus.completed;
              final done = completedAll || (idx >= 0 && i < idx);
              final current = !completedAll && idx >= 0 && i == idx;
              final color = done || current
                  ? theme.colorScheme.primary
                  : theme.dividerColor;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: current || done
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(color: color.withValues(alpha: 0.45)),
                      ),
                      child: Center(
                        child: done
                            ? Icon(Icons.check, size: 14, color: theme.colorScheme.onPrimary)
                            : current
                                ? Icon(Icons.circle, size: 8, color: theme.colorScheme.onPrimary)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                        color: current
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
