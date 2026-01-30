import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/colors.dart';
import '../screens/sidebars/notifications_sidebar.dart';

enum MapFilterOption { mechanics, autoParts, events }

class HomeMapFabColumn extends StatefulWidget {
  final VoidCallback? onDriveMode;
  final VoidCallback? onRecenter;
  final ValueChanged<bool>? onHeatmapChanged;
  final ValueChanged<Set<MapFilterOption>>? onFilterChanged;
  final bool isHeatmapOn;
  final Set<MapFilterOption> selectedFilters;

  const HomeMapFabColumn({
    super.key,
    this.onDriveMode,
    this.onRecenter,
    this.onHeatmapChanged,
    this.onFilterChanged,
    this.isHeatmapOn = false,
    this.selectedFilters = const {},
  });

  @override
  State<HomeMapFabColumn> createState() => _HomeMapFabColumnState();
}

class _HomeMapFabColumnState extends State<HomeMapFabColumn> {
  bool _heatmapOn = false;
  Set<MapFilterOption> _filters = {};
  bool _filterMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _heatmapOn = widget.isHeatmapOn;
    _filters = Set.from(widget.selectedFilters);
  }

  @override
  void didUpdateWidget(HomeMapFabColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHeatmapOn != widget.isHeatmapOn) _heatmapOn = widget.isHeatmapOn;
    if (oldWidget.selectedFilters != widget.selectedFilters) _filters = Set.from(widget.selectedFilters);
  }

  void _showNotifications() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSidebar(),
    );
  }

  void _toggleHeatmap() {
    setState(() => _heatmapOn = !_heatmapOn);
    widget.onHeatmapChanged?.call(_heatmapOn);
  }

  void _toggleFilterMenu() {
    setState(() => _filterMenuOpen = !_filterMenuOpen);
  }

  void _toggleFilter(MapFilterOption opt) {
    setState(() {
      if (_filters.contains(opt)) {
        _filters.remove(opt);
      } else {
        _filters.add(opt);
      }
    });
    widget.onFilterChanged?.call(Set.from(_filters));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _fab(
          context: context,
          icon: LucideIcons.car,
          label: 'Modo Drive',
          color: AppColors.racingOrange,
          onTap: widget.onDriveMode,
          isHighlight: true,
        ),
        const SizedBox(height: 12),
        _fab(
          context: context,
          icon: LucideIcons.bell,
          label: 'Notificações',
          color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.55),
          onTap: _showNotifications,
        ),
        const SizedBox(height: 12),
        _fab(
          context: context,
          icon: LucideIcons.flame,
          label: 'Zona Quente',
          color: _heatmapOn ? AppColors.racingOrange.withOpacity(0.9) : (isDark ? Colors.white.withOpacity(0.45) : Colors.black.withOpacity(0.45)),
          onTap: _toggleHeatmap,
        ),
        const SizedBox(height: 12),
        _fab(
          context: context,
          icon: LucideIcons.filter,
          label: 'Filtros',
          color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.55),
          onTap: _filterMenuOpen ? null : _toggleFilterMenu,
        ),
        if (_filterMenuOpen) ...[
          const SizedBox(height: 8),
          _filterChips(theme),
        ],
        const SizedBox(height: 12),
        _fab(
          context: context,
          icon: LucideIcons.crosshair,
          label: 'Re-center',
          color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.55),
          onTap: widget.onRecenter,
        ),
      ],
    );
  }

  Widget _fab({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isHighlight ? color.withOpacity(0.9) : (theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06)),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                if (isHighlight)
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: isHighlight ? Colors.white : color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Visualização',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('Mecânicos', MapFilterOption.mechanics, theme),
              _chip('Auto Peças', MapFilterOption.autoParts, theme),
              _chip('Eventos', MapFilterOption.events, theme),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _toggleFilterMenu,
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, MapFilterOption opt, ThemeData theme) {
    final selected = _filters.contains(opt);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _toggleFilter(opt),
      selectedColor: AppColors.racingOrange.withOpacity(0.3),
      checkmarkColor: AppColors.racingOrange,
    );
  }
}
