import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Navegação inferior com 5 destinos: Chat, Eventos, Menu (central), Momentos, Garagem.
class FloatingBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingBottomNav> createState() => _FloatingBottomNavState();
}

class _FloatingBottomNavState extends State<FloatingBottomNav> {
  static final List<NavItem> _navItems = [
    NavItem(icon: LucideIcons.messageCircle, label: 'Chat', index: 0),
    NavItem(icon: LucideIcons.calendarDays, label: 'Eventos', index: 1),
    NavItem(icon: LucideIcons.layoutGrid, label: 'Menu', index: 2),
    NavItem(icon: LucideIcons.sparkles, label: 'Momentos', index: 3),
    NavItem(icon: LucideIcons.box, label: 'Garagem', index: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.currentIndex.clamp(0, _navItems.length - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.2),
                borderRadius: BorderRadius.circular(28),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final itemWidth = barWidth / _navItems.length;
                  final pillWidth = itemWidth - 12;
                  final pillLeft = 6 + currentIndex * itemWidth + (itemWidth - pillWidth) / 2;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: pillLeft,
                        top: 6,
                        child: Container(
                          width: pillWidth,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: _navItems.asMap().entries.map((entry) {
                          final item = entry.value;
                          final isSelected = currentIndex == item.index;
                          final iconColor = isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.5));

                          return Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => widget.onTap(item.index),
                                borderRadius: BorderRadius.circular(22),
                                splashColor: theme.colorScheme.primary.withOpacity(0.15),
                                highlightColor: theme.colorScheme.primary.withOpacity(0.08),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    item.icon,
                                    size: 22,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final int index;

  const NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
