import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/delivery_order.dart';
import '../utils/colors.dart';
import 'api_image.dart';

/// Detalhes do motociclista (lojista) + foto ampliável.
class PartnerRiderDetailSheet extends StatelessWidget {
  const PartnerRiderDetailSheet({
    super.key,
    required this.order,
  });

  final DeliveryOrder order;

  static Future<void> show(BuildContext context, DeliveryOrder order) {
    if ((order.riderId ?? '').isEmpty && (order.riderName ?? '').isEmpty) {
      return Future.value();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PartnerRiderDetailSheet(order: order),
    );
  }

  static void showPhotoFullscreen(BuildContext context, String url, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _RiderPhotoFullscreen(url: url, heroTag: heroTag),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final name = order.riderName ?? 'Motociclista';
    final photoUrl = order.riderPhotoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final heroTag = 'partner_rider_photo_${order.id}';

    final bikeParts = <String>[
      if ((order.riderBikeModel ?? '').trim().isNotEmpty) order.riderBikeModel!.trim(),
      if ((order.riderBikePlate ?? '').trim().isNotEmpty) order.riderBikePlate!.trim(),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.panelDarkHigh : AppColors.panelLightHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: AppColors.raisedPanelShadows(isDark),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Entregador',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.racingOrange,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hasPhoto
                          ? () => showPhotoFullscreen(context, photoUrl, heroTag)
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Hero(
                        tag: heroTag,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.racingOrange.withValues(alpha: 0.45),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.racingOrange.withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: hasPhoto
                                  ? ApiImage(url: photoUrl, fit: BoxFit.cover)
                                  : ColoredBox(
                                      color: AppColors.racingOrange.withValues(alpha: 0.12),
                                      child: Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: theme.textTheme.displaySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.racingOrange,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            if (hasPhoto)
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  LucideIcons.zoomIn,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Toque na foto para ampliar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _InfoTile(
                  icon: LucideIcons.bike,
                  label: 'Veículo',
                  value: bikeParts.isEmpty ? 'Não informado' : bikeParts.join(' · '),
                ),
                if (order.riderPhone != null && order.riderPhone!.isNotEmpty)
                  _InfoTile(
                    icon: LucideIcons.phone,
                    label: 'Telefone',
                    value: order.riderPhone!,
                    onTap: () => _callPhone(context, order.riderPhone!),
                    trailing: const Icon(LucideIcons.externalLink, size: 16),
                  ),
                if (order.riderEmail != null && order.riderEmail!.isNotEmpty)
                  _InfoTile(
                    icon: LucideIcons.mail,
                    label: 'E-mail',
                    value: order.riderEmail!,
                  ),
                if (order.internalCode != null && order.internalCode!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.neonGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.hash, size: 16, color: AppColors.neonGreen),
                            const SizedBox(width: 8),
                            Text(
                              'Código de retirada (4 dígitos)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.internalCode!,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: AppColors.neonGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.racingOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$digits');
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o telefone.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.racingOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RiderPhotoFullscreen extends StatelessWidget {
  const _RiderPhotoFullscreen({
    required this.url,
    required this.heroTag,
  });

  final String url;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: ApiImage(url: url, fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
