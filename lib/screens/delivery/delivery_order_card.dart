import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/delivery_order.dart';
import '../../utils/colors.dart';

class DeliveryOrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final bool showAcceptButton;

  const DeliveryOrderCard({
    super.key,
    required this.order,
    required this.userLat,
    required this.userLng,
    required this.onTap,
    this.onAccept,
    this.showAcceptButton = false,
  });

  Color _getPriorityColor(DeliveryPriority priority) {
    switch (priority) {
      case DeliveryPriority.urgent:
        return Colors.red;
      case DeliveryPriority.high:
        return AppColors.racingOrange;
      case DeliveryPriority.normal:
        return Colors.blue;
      case DeliveryPriority.low:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(DeliveryPriority priority) {
    switch (priority) {
      case DeliveryPriority.urgent:
        return 'Urgente';
      case DeliveryPriority.high:
        return 'Alta';
      case DeliveryPriority.normal:
        return 'Normal';
      case DeliveryPriority.low:
        return 'Baixa';
    }
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.accepted:
        return Colors.blue;
      case DeliveryStatus.inProgress:
        return AppColors.racingOrange;
      case DeliveryStatus.completed:
        return AppColors.neonGreen;
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Aguardando';
      case DeliveryStatus.accepted:
        return 'Aceito';
      case DeliveryStatus.inProgress:
        return 'Em andamento';
      case DeliveryStatus.completed:
        return 'Concluído';
      case DeliveryStatus.cancelled:
        return 'Cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = order.distanceFromStore(userLat, userLng);
    final totalDistance = order.totalDistance;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com loja e status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.racingOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.store,
                    color: AppColors.racingOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusLabel(order.status),
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(order.priority).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getPriorityLabel(order.priority),
                              style: TextStyle(
                                color: _getPriorityColor(order.priority),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Valor da entrega
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${order.deliveryFee.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Taxa',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Rota
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.racingOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 20,
                      color: AppColors.racingOrange.withOpacity(0.3),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeAddress,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.deliveryAddress,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações adicionais
            Row(
              children: [
                _buildInfoChip(
                  theme,
                  icon: LucideIcons.mapPin,
                  label: '${distance.toStringAsFixed(1)} km até loja',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  theme,
                  icon: LucideIcons.navigation,
                  label: '${totalDistance.toStringAsFixed(1)} km total',
                ),
                if (order.estimatedTime != null) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    theme,
                    icon: LucideIcons.clock,
                    label: '${order.estimatedTime} min',
                  ),
                ],
              ],
            ),
            
            if (showAcceptButton && order.status == DeliveryStatus.pending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.racingOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.check),
                      const SizedBox(width: 8),
                      Text(
                        'Aceitar Corrida',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

