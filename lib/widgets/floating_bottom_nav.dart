import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/colors.dart';
import '../providers/app_state_provider.dart';

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

class _FloatingBottomNavState extends State<FloatingBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(FloatingBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getNormalizedIndex(int index) {
    // Converte índice especial 99 (delivery) para índice 5
    if (index == 99) return 5;
    return index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final normalizedIndex = _getNormalizedIndex(widget.currentIndex);
    
    // Verificar se é lojista
    final appState = Provider.of<AppStateProvider>(context);
    final isPartner = appState.user?.isPartner ?? false;

    // Menu para motociclistas
    final riderNavItems = [
      {'icon': LucideIcons.home, 'label': 'Home', 'index': 0},
      {'icon': LucideIcons.wrench, 'label': 'Manutenção', 'index': 1},
      {'icon': LucideIcons.store, 'label': 'Parceiros', 'index': 2},
      {'icon': LucideIcons.trophy, 'label': 'Ranking', 'index': 3},
      {'icon': LucideIcons.users, 'label': 'Comunidade', 'index': 4},
      {'icon': LucideIcons.package, 'label': 'Delivery', 'index': 5},
    ];

    // Menu para lojistas (apenas Home e Delivery)
    final partnerNavItems = [
      {'icon': LucideIcons.home, 'label': 'Home', 'index': 0},
      {'icon': LucideIcons.package, 'label': 'Pedidos', 'index': 5},
    ];

    final navItems = isPartner ? partnerNavItems : riderNavItems;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / navItems.length;
              
              // Mapear índice real para índice no menu filtrado
              int getFilteredIndex(int realIndex) {
                if (isPartner) {
                  // Para lojistas: 0 = Home, 5 = Delivery
                  if (realIndex == 0) return 0;
                  if (realIndex == 5) return 1;
                  return 0; // Default
                } else {
                  return realIndex;
                }
              }
              
              final filteredIndex = getFilteredIndex(normalizedIndex);
              
              return Stack(
                children: [
                  // Círculo laranja animado de fundo
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    left: itemWidth * filteredIndex,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: itemWidth,
                        height: 54,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  // Ícones do menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: navItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final realIndex = item['index'] as int;
                      final isSelected = normalizedIndex == realIndex;

                      return Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final targetIndex = item['index'] as int;
                              if (targetIndex == 5) {
                                widget.onTap(99); // Valor especial para delivery
                              } else {
                                widget.onTap(targetIndex);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  item['icon'] as IconData,
                                  key: ValueKey('${item['icon']}_$isSelected'),
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.black.withOpacity(0.5)),
                                  size: 24,
                                ),
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
    );
  }
}
