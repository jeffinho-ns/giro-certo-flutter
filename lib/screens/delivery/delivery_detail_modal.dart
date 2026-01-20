import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/delivery_order.dart';
import '../../utils/colors.dart';

class DeliveryDetailModal extends StatelessWidget {
  final DeliveryOrder order;
  final double userLat;
  final double userLng;
  final VoidCallback? onAccept;
  final VoidCallback? onComplete;
  final bool isRider;

  const DeliveryDetailModal({
    super.key,
    required this.order,
    required this.userLat,
    required this.userLng,
    this.onAccept,
    this.onComplete,
    this.isRider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storePoint = LatLng(order.storeLatitude, order.storeLongitude);
    final deliveryPoint = LatLng(order.deliveryLatitude, order.deliveryLongitude);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.racingOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.package,
                            color: AppColors.racingOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedido #${order.id.substring(1)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                order.storeName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'R\$ ${order.deliveryFee.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Mapa
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: storePoint,
                            initialZoom: 14.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.girocerto.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: storePoint,
                                  width: 50,
                                  height: 50,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.racingOrange,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                        ),
                                        child: const Icon(
                                          LucideIcons.store,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Loja',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Marker(
                                  point: deliveryPoint,
                                  width: 50,
                                  height: 50,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.neonGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                        ),
                                        child: const Icon(
                                          LucideIcons.mapPin,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Entrega',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Informações da loja
                    _buildInfoSection(
                      theme,
                      title: 'Loja',
                      icon: LucideIcons.store,
                      address: order.storeAddress,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Informações da entrega
                    _buildInfoSection(
                      theme,
                      title: 'Entrega',
                      icon: LucideIcons.mapPin,
                      address: order.deliveryAddress,
                      recipientName: order.recipientName,
                      recipientPhone: order.recipientPhone,
                    ),
                    
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.messageSquare,
                              color: AppColors.racingOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Observações',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.notes!,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Detalhes do pedido
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(theme, 'Valor do pedido', 'R\$ ${order.value.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _buildDetailRow(theme, 'Taxa de entrega', 'R\$ ${order.deliveryFee.toStringAsFixed(2)}'),
                          const Divider(height: 24),
                          _buildDetailRow(
                            theme,
                            'Total',
                            'R\$ ${order.totalValue.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            theme,
                            'Distância total',
                            '${order.totalDistance.toStringAsFixed(1)} km',
                          ),
                          if (order.estimatedTime != null)
                            _buildDetailRow(
                              theme,
                              'Tempo estimado',
                              '${order.estimatedTime} minutos',
                            ),
                        ],
                      ),
                    ),
                    
                    if (isRider && order.status == DeliveryStatus.pending && onAccept != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.racingOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                    
                    if (isRider && order.status == DeliveryStatus.inProgress && onComplete != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.checkCircle),
                              const SizedBox(width: 8),
                              Text(
                                'Marcar como Concluído',
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
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required String address,
    String? recipientName,
    String? recipientPhone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.racingOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address,
            style: theme.textTheme.bodyMedium,
          ),
          if (recipientName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.user, size: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  recipientName,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (recipientPhone != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.phone, size: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  recipientPhone,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.neonGreen : null,
            fontSize: isTotal ? 18 : null,
          ),
        ),
      ],
    );
  }
}

