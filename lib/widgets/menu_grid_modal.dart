import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/colors.dart';
import '../screens/maintenance/maintenance_detail_screen.dart';
import '../screens/partners/partners_screen.dart';
import '../screens/delivery/delivery_screen.dart';

/// routeIndex: 0=Chat, 1=Eventos, 4=Garagem (navega tab). 101=Manutenção, 102=Parceiros, 105=Delivery (push).
class MenuGridModal extends StatelessWidget {
  final VoidCallback? onClose;
  final Function(int)? onNavigateToIndex;

  const MenuGridModal({
    super.key,
    this.onClose,
    this.onNavigateToIndex,
  });

  static const List<MenuGridItem> items = [
    MenuGridItem(icon: LucideIcons.wrench, label: 'Manutenção Detalhada', routeIndex: 101),
    MenuGridItem(icon: LucideIcons.store, label: 'Parceiros e Mecânicos', routeIndex: 102),
    MenuGridItem(icon: LucideIcons.package, label: 'Corridas', routeIndex: 105, highlight: true),
    MenuGridItem(icon: LucideIcons.camera, label: 'Foto Sport', routeIndex: -1),
    MenuGridItem(icon: LucideIcons.mapPin, label: 'Rotas', routeIndex: -1),
    MenuGridItem(icon: LucideIcons.helpCircle, label: 'Help', routeIndex: -1),
    MenuGridItem(icon: LucideIcons.newspaper, label: 'News', routeIndex: -1),
    MenuGridItem(icon: LucideIcons.car, label: 'Modo Drive', routeIndex: -1),
    MenuGridItem(icon: LucideIcons.bike, label: 'Veículos', routeIndex: 4),
    MenuGridItem(icon: LucideIcons.users, label: 'Comunidades', routeIndex: 0),
    MenuGridItem(icon: LucideIcons.search, label: 'Pesquisar', routeIndex: -1),
    MenuGridItem(icon: LucideIcons.userPlus, label: 'Amigos', routeIndex: -1),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onClose?.call();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: items.map((item) => _GridTile(
                    item: item,
                    theme: theme,
                    onTap: () {
                      onClose?.call();
                      Navigator.of(context).pop();
                      if (item.routeIndex >= 0 && item.routeIndex <= 4 && onNavigateToIndex != null) {
                        onNavigateToIndex!(item.routeIndex);
                      } else if (item.routeIndex == 101) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MaintenanceDetailScreen()),
                        );
                      } else if (item.routeIndex == 102) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PartnersScreen()),
                        );
                      } else if (item.routeIndex == 105) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DeliveryScreen()),
                        );
                      }
                    },
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuGridItem {
  final IconData icon;
  final String label;
  final int routeIndex; // -1 = placeholder
  final bool highlight;

  const MenuGridItem({
    required this.icon,
    required this.label,
    this.routeIndex = -1,
    this.highlight = false,
  });
}

class _GridTile extends StatelessWidget {
  final MenuGridItem item;
  final ThemeData theme;
  final VoidCallback onTap;

  const _GridTile({
    required this.item,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlight = item.highlight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isHighlight
                ? AppColors.racingOrange.withOpacity(0.1)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHighlight
                  ? AppColors.racingOrange.withOpacity(0.25)
                  : theme.dividerColor.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? AppColors.racingOrange.withOpacity(0.18)
                      : theme.colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: isHighlight ? AppColors.racingOrange.withOpacity(0.95) : theme.colorScheme.primary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
                  color: isHighlight ? AppColors.racingOrange.withOpacity(0.95) : theme.textTheme.bodySmall?.color?.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
