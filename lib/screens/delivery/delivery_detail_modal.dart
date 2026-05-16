import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/delivery_order.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../utils/delivery_status_utils.dart';

class DeliveryDetailModal extends StatefulWidget {
  final DeliveryOrder order;
  final double userLat;
  final double userLng;
  final VoidCallback? onAccept;
  final VoidCallback? onComplete;
  final VoidCallback? onOrderUpdated;
  final bool isRider;
  final bool showRouteHistory;
  /// `prepaid` | `postpaid_pix` | `authorize_capture` da API (`delivery_payment_collection_mode`).
  final String? partnerCollectionMode;

  const DeliveryDetailModal({
    super.key,
    required this.order,
    required this.userLat,
    required this.userLng,
    this.onAccept,
    this.onComplete,
    this.onOrderUpdated,
    this.isRider = true,
    this.showRouteHistory = false,
    this.partnerCollectionMode,
  });

  @override
  State<DeliveryDetailModal> createState() => _DeliveryDetailModalState();
}

class _DeliveryDetailModalState extends State<DeliveryDetailModal> {
  List<LatLng> _routeHistory = const [];
  bool _isLoadingHistory = false;
  Map<String, dynamic>? _latestPayment;
  bool _loadingLatestPayment = false;

  String get _modeEffective {
    final m = widget.partnerCollectionMode?.trim();
    if (m == null || m.isEmpty) return 'prepaid';
    return m;
  }

  bool get _isPartnerPrepaid => _modeEffective == 'prepaid';

  /// Default Asaas `billingType` alinhado ao modo da loja (API aplica o mesmo).
  String? get _billingTypeForInitiate {
    if (_modeEffective == 'postpaid_pix') return 'PIX';
    if (_modeEffective == 'authorize_capture') return 'CREDIT_CARD';
    return null;
  }

  bool get _showsPaymentCheckout {
    if (widget.isRider) return false;
    return DeliveryStatusUtils.allowsStorePaymentCheckout(
      widget.order.status,
      widget.partnerCollectionMode,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRouteHistoryIfNeeded();
    if (!widget.isRider) {
      unawaited(_refreshLatestPayment());
    }
  }

  Future<void> _loadRouteHistoryIfNeeded() async {
    if (!widget.showRouteHistory ||
        widget.order.status != DeliveryStatus.completed) {
      return;
    }
    setState(() => _isLoadingHistory = true);
    try {
      final points = await ApiService.getDeliveryRouteHistory(widget.order.id);
      if (!mounted) return;
      setState(() {
        _routeHistory = points
            .where((p) => p['lat'] is num && p['lng'] is num)
            .map((p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ))
            .toList();
      });
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _refreshLatestPayment() async {
    setState(() => _loadingLatestPayment = true);
    try {
      final m = await ApiService.getLatestDeliveryPayment(widget.order.id);
      if (!mounted) return;
      setState(() {
        _latestPayment = m;
        _loadingLatestPayment = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latestPayment = null;
        _loadingLatestPayment = false;
      });
    }
  }

  Future<void> _generateAndOpenCheckout() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final payment = await ApiService.initiateDeliveryPayment(
        widget.order.id,
        billingType: _billingTypeForInitiate,
      );
      final url = payment['invoiceUrl'] as String?;
      if (url == null || url.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Link da cobrança indisponível. Tente de novo.'),
          ),
        );
        return;
      }
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link de pagamento.'),
          ),
        );
      }
      widget.onOrderUpdated?.call();
      await _refreshLatestPayment();
      if (!mounted) return;
      _showPaymentResultSheet(context, payment);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao gerar cobrança: $e')),
      );
    }
  }

  Future<void> _openLinkOnly(Map<String, dynamic> payment) async {
    final url = payment['invoiceUrl'] as String?;
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showPaymentResultSheet(
    BuildContext context,
    Map<String, dynamic> payment,
  ) {
    final theme = Theme.of(context);
    final pix = payment['pixCopyPaste'] as String?;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cobrança criada',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (pix != null && pix.trim().isNotEmpty) ...[
                Text(
                  'PIX copia e cola:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  pix.trim(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: pix.trim()));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('PIX copiado.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar PIX'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => unawaited(_openLinkOnly(payment)),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Abrir página de pagamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final order = widget.order;
    final storePoint = LatLng(order.storeLatitude, order.storeLongitude);
    final deliveryPoint =
        LatLng(order.deliveryLatitude, order.deliveryLongitude);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
                isDark ? AppColors.panelDarkLow : AppColors.panelLightLow,
              ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: AppColors.raisedPanelShadows(isDark),
          ),
          child: Column(
            children: [
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.racingOrangeLight
                                    .withOpacity(0.95),
                                AppColors.racingOrangeDark.withOpacity(0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.insetPanelShadows(isDark),
                          ),
                          child: Icon(
                            LucideIcons.package,
                            color: Colors.white,
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
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppColors.neonGreen.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            'R\$ ${order.deliveryFee.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.neonGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        boxShadow: AppColors.insetPanelShadows(isDark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: storePoint,
                            zoom: 14.0,
                          ),
                          mapType: MapType.normal,
                          markers: {
                            Marker(
                              markerId: const MarkerId('store'),
                              position: storePoint,
                              infoWindow: const InfoWindow(title: 'Loja'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueOrange,
                              ),
                            ),
                            Marker(
                              markerId: const MarkerId('delivery'),
                              position: deliveryPoint,
                              infoWindow: const InfoWindow(title: 'Entrega'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                          },
                          polylines: _routeHistory.length >= 2
                              ? {
                                  Polyline(
                                    polylineId: const PolylineId(
                                        'delivery_route_history'),
                                    points: _routeHistory,
                                    color: AppColors.racingOrange,
                                    width: 5,
                                  ),
                                }
                              : {},
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                    if (widget.showRouteHistory &&
                        order.status == DeliveryStatus.completed) ...[
                      const SizedBox(height: 8),
                      if (_isLoadingHistory)
                        const LinearProgressIndicator(minHeight: 2),
                      if (!_isLoadingHistory && _routeHistory.isNotEmpty)
                        Text(
                          'Trajeto real da entrega: ${_routeHistory.length} pontos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.racingOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    _buildInfoSection(
                      theme,
                      title: 'Loja',
                      icon: LucideIcons.store,
                      address: order.storeAddress,
                    ),
                    const SizedBox(height: 16),
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark
                                  ? AppColors.panelDarkHigh
                                  : AppColors.panelLightHigh,
                              isDark
                                  ? AppColors.panelDarkLow
                                  : AppColors.panelLightLow,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                          boxShadow: AppColors.insetPanelShadows(isDark),
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
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            isDark
                                ? AppColors.panelDarkHigh
                                : AppColors.panelLightHigh,
                            isDark
                                ? AppColors.panelDarkLow
                                : AppColors.panelLightLow,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                        boxShadow: AppColors.insetPanelShadows(isDark),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(theme, 'Valor do pedido',
                              'R\$ ${order.value.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _buildDetailRow(theme, 'Taxa de entrega',
                              'R\$ ${order.deliveryFee.toStringAsFixed(2)}'),
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
                    if (!widget.isRider &&
                        (_loadingLatestPayment ||
                            (_latestPayment != null &&
                                _latestPayment!.isNotEmpty))) ...[
                      const SizedBox(height: 16),
                      if (_loadingLatestPayment)
                        const LinearProgressIndicator(minHeight: 2)
                      else ...[
                        _buildPaymentSummaryChip(theme, _latestPayment!),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => unawaited(_refreshLatestPayment()),
                            icon: Icon(
                              Icons.refresh,
                              size: 16,
                              color: AppColors.racingOrangeDark,
                            ),
                            label: Text(
                              'Atualizar pagamento',
                              style: TextStyle(
                                color: AppColors.racingOrangeDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                    if (!widget.isRider &&
                        order.status == DeliveryStatus.awaitingDispatch) ...[
                      if (_showsPaymentCheckout) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                unawaited(_generateAndOpenCheckout()),
                            icon: const Icon(LucideIcons.banknote, size: 18),
                            label: Text(
                              _isPartnerPrepaid
                                  ? 'Gerar link de pagamento (PIX/cartão)'
                                  : (_modeEffective == 'postpaid_pix'
                                      ? 'Gerar PIX (opcional antes de despachar)'
                                      : 'Gerar cobrança ao cliente'),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.racingOrangeDark,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              side: BorderSide(
                                color: AppColors.racingOrangeDark
                                    .withValues(alpha: 0.65),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await ApiService.dispatchOrder(order.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pedido liberado. O app esta notificando motociclistas na regiao.',
                                  ),
                                ),
                              );
                              widget.onOrderUpdated?.call();
                              Navigator.of(context).pop();
                            } catch (e) {
                              if (!context.mounted) return;
                              if (e is ApiStructuredException &&
                                  e.code == 'PAYMENT_REQUIRED_PREPAID') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.message),
                                    action: SnackBarAction(
                                      label: 'Cobrar',
                                      onPressed: () => unawaited(
                                        _generateAndOpenCheckout(),
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Nao foi possivel chamar motociclista: $e',
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.racingOrangeDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    Colors.white.withOpacity(0.2),
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.bike),
                              SizedBox(width: 8),
                              Text(
                                'Confirmar e Chamar Motociclista',
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
                    if (!widget.isRider &&
                        !_isPartnerPrepaid &&
                        DeliveryStatusUtils.isActive(order.status)) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => unawaited(_generateAndOpenCheckout()),
                          icon: const Icon(LucideIcons.smartphone,
                              size: 18),
                          label: Text(
                            _modeEffective == 'postpaid_pix'
                                ? 'Cobrar cliente agora (PIX)'
                                : 'Gerar cobrança ao cliente',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                AppColors.racingOrangeDark.withValues(
                                    alpha: 0.95),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: AppColors.racingOrangeDark
                                  .withValues(alpha: 0.65),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (widget.isRider &&
                        order.status == DeliveryStatus.pending &&
                        widget.onAccept != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onAccept?.call();
                            widget.onOrderUpdated?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.racingOrangeDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            elevation: 0,
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
                    if (widget.isRider &&
                        order.status == DeliveryStatus.arrivedAtDestination &&
                        widget.onComplete != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onComplete?.call();
                            widget.onOrderUpdated?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            elevation: 0,
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

  Widget _buildPaymentSummaryChip(
    ThemeData theme,
    Map<String, dynamic> payment,
  ) {
    final status = '${payment['status'] ?? '?'}'.toUpperCase();
    Color bg =
        Colors.orange.withValues(alpha: 0.22);
    if (status == 'PAID') {
      bg = AppColors.neonGreen.withValues(alpha: 0.25);
    } else if (status.contains('FAIL') ||
        status == 'EXPIRED' ||
        status == 'CANCELLED') {
      bg = theme.colorScheme.error.withValues(alpha: 0.2);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Última cobrança',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Estado Asaas/local: ${payment['status'] ?? '?'} • '
            'Cliente: ${_formatMoney(payment['customerTotal'])}',
            style: theme.textTheme.bodySmall,
          ),
          if (payment['pixCopyPaste'] is String &&
              (payment['pixCopyPaste'] as String).trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final p = (payment['pixCopyPaste'] as String).trim();
                await Clipboard.setData(ClipboardData(text: p));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIX copiado.')),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar PIX da última cobrança'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatMoney(dynamic v) {
    if (v is num) {
      return 'R\$ ${v.toDouble().toStringAsFixed(2)}';
    }
    return '?';
  }

  Widget _buildInfoSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required String address,
    String? recipientName,
    String? recipientPhone,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
            isDark ? AppColors.panelDarkLow : AppColors.panelLightLow,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: AppColors.insetPanelShadows(isDark),
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
                Icon(LucideIcons.user,
                    size: 16,
                    color:
                        theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
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
                Icon(LucideIcons.phone,
                    size: 16,
                    color:
                        theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
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

  Widget _buildDetailRow(ThemeData theme, String label, String value,
      {bool isTotal = false}) {
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
