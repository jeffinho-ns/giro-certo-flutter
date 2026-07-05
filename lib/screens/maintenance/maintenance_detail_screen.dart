import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../services/maintenance_service.dart';
import '../../services/mock_data_service.dart';
import '../../models/maintenance.dart';
import '../../models/bike.dart';
import '../../models/partner.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../partners/voucher_modal.dart';
import '../garage/garage_screen.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  const MaintenanceDetailScreen({super.key});

  @override
  State<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  List<Maintenance> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final bike = appState.bike;
    if (bike == null) {
      if (mounted) {
        setState(() {
          _items = const [];
          _loading = false;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await MaintenanceService.loadMaintenances(bike);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = 'Não foi possível carregar a manutenção. Tenta novamente.';
      });
    }
  }

  Future<void> _updateKmFlow(Bike bike) async {
    final newKm = await _showUpdateKmDialog(bike);
    if (newKm == null) return;
    try {
      final updated = await MaintenanceService.updateBikeKm(bike, newKm);
      if (!mounted) return;
      Provider.of<AppStateProvider>(context, listen: false).setBike(updated);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quilometragem atualizada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar km: $e')),
      );
    }
  }

  Future<int?> _showUpdateKmDialog(Bike bike) async {
    final controller =
        TextEditingController(text: bike.currentKm.toString());
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Atualizar quilometragem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insira a quilometragem atual da sua ${bike.isBicycle ? "bicicleta" : "moto"}.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'km',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < bike.currentKm) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'A nova quilometragem precisa ser maior ou igual a ${bike.currentKm} km.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop(value);
              },
              child: const Text('Atualizar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markDoneFlow(Bike bike, Maintenance maintenance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar troca de ${maintenance.partName}?'),
        content: Text(
          'Iremos marcar a troca para a quilometragem atual (${NumberFormat('#,###').format(bike.currentKm)} km).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MaintenanceService.registerMaintenance(
        bike: bike,
        maintenance: maintenance,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${maintenance.partName} marcado como trocado.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao registrar troca: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike;
    final theme = Theme.of(context);

    if (bike == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ModernHeader(
                title: 'Manutenção Detalhada',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(child: _buildEmptyGarage(theme)),
            ],
          ),
        ),
      );
    }

    final summary = MaintenanceService.buildSummary(_items);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Manutenção Detalhada',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    if (!_loading && _error == null)
                      _buildCriticalAlertBanner(summary, theme),
                    _buildHeaderCard(bike, summary, theme),
                    const SizedBox(height: 20),
                    if (_loading)
                      ...List.generate(
                        4,
                        (_) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SkeletonCard(),
                        ),
                      )
                    else if (_error != null)
                      _buildErrorState(theme)
                    else if (_items.isEmpty)
                      _buildNoItemsState(theme)
                    else
                      ..._sortedItems.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildMaintenanceCard(bike, m, theme),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGarage(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.bike,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Configure sua moto na garagem',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Para acompanhar a manutenção é preciso cadastrar uma moto e a quilometragem atual.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GarageScreen()),
                );
              },
              icon: const Icon(LucideIcons.plusCircle),
              label: const Text('Ir para a Garagem'),
            ),
          ],
        ),
      ),
    );
  }

  List<Maintenance> get _sortedItems {
    final priority = {'Crítico': 0, 'Atenção': 1, 'OK': 2};
    final list = List<Maintenance>.from(_items);
    list.sort((a, b) {
      final pa = priority[a.status] ?? 3;
      final pb = priority[b.status] ?? 3;
      if (pa != pb) return pa.compareTo(pb);
      return b.wearPercentage.compareTo(a.wearPercentage);
    });
    return list;
  }

  Widget _buildCriticalAlertBanner(
      MaintenanceSummary summary, ThemeData theme) {
    if (!summary.hasCritical && !summary.hasWarning) {
      return const SizedBox.shrink();
    }
    final isCritical = summary.hasCritical;
    final color =
        isCritical ? AppColors.statusCritical : AppColors.statusWarning;
    final criticalItems = _items
        .where((m) => m.status == 'Crítico')
        .map((m) => m.partName)
        .toList();
    final warningItems = _items
        .where((m) => m.status == 'Atenção')
        .map((m) => m.partName)
        .toList();
    final oilAlert = _items.any((m) =>
        (m.id == 'oil' ||
            m.partName.toLowerCase().contains('óleo') ||
            m.partName.toLowerCase().contains('oleo')) &&
        (m.status == 'Crítico' || m.status == 'Atenção'));

    final highlight = oilAlert
        ? 'Óleo do motor precisa de atenção.'
        : (criticalItems.isNotEmpty
            ? criticalItems.take(2).join(', ')
            : warningItems.take(2).join(', '));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.55), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCritical ? LucideIcons.alertTriangle : LucideIcons.alertCircle,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCritical
                        ? 'Ação recomendada agora'
                        : 'Itens em atenção',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    oilAlert
                        ? '$highlight ${isCritical ? 'Troca urgente.' : 'Planeje a troca em breve.'}'
                        : '$highlight${criticalItems.length + warningItems.length > 2 ? ' e mais.' : '.'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  if (summary.criticalCount > 0 || summary.warningCount > 0) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (summary.criticalCount > 0)
                          _alertBadge(
                            '${summary.criticalCount} crítico${summary.criticalCount == 1 ? '' : 's'}',
                            AppColors.statusCritical,
                          ),
                        if (summary.warningCount > 0)
                          _alertBadge(
                            '${summary.warningCount} em atenção',
                            AppColors.statusWarning,
                          ),
                        if (oilAlert)
                          _alertBadge('Óleo', color),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
      Bike bike, MaintenanceSummary summary, ThemeData theme) {
    final formattedKm = NumberFormat('#,###').format(bike.currentKm);
    final healthPct = (summary.overallHealth * 100).round();
    Color healthColor;
    if (summary.criticalCount > 0) {
      healthColor = AppColors.statusCritical;
    } else if (summary.warningCount > 0) {
      healthColor = AppColors.statusWarning;
    } else {
      healthColor = AppColors.statusOk;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.racingOrange.withOpacity(0.18),
            AppColors.racingOrangeDark.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.racingOrange.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.racingOrange.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  bike.isBicycle ? LucideIcons.bike : LucideIcons.gauge,
                  color: AppColors.racingOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bike.brand} ${bike.model}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Placa ${bike.plate} • $formattedKm km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: healthColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.heartPulse,
                        size: 14, color: healthColor),
                    const SizedBox(width: 4),
                    Text(
                      '$healthPct%',
                      style: TextStyle(
                        color: healthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryChip(
                  theme,
                  icon: LucideIcons.checkCircle,
                  color: AppColors.statusOk,
                  label: 'OK',
                  count: summary.okCount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryChip(
                  theme,
                  icon: LucideIcons.alertCircle,
                  color: AppColors.statusWarning,
                  label: 'Atenção',
                  count: summary.warningCount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryChip(
                  theme,
                  icon: LucideIcons.alertTriangle,
                  color: AppColors.statusCritical,
                  label: 'Crítico',
                  count: summary.criticalCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateKmFlow(bike),
                  icon: const Icon(LucideIcons.gauge, size: 18),
                  label: const Text('Atualizar km'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.racingOrange,
                    side: BorderSide(
                      color: AppColors.racingOrange.withOpacity(0.6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(LucideIcons.refreshCcw, size: 18),
                  label: const Text('Recalcular'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.racingOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.cloudOff,
              size: 40, color: AppColors.statusWarning),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Erro desconhecido',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoItemsState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.checkCircle,
              size: 40, color: AppColors.statusOk),
          const SizedBox(height: 12),
          Text(
            'Tudo em dia',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Sem itens recomendados para o seu tipo de veículo no momento.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(
      Bike bike, Maintenance maintenance, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;

    if (maintenance.status == 'OK') {
      statusColor = AppColors.statusOk;
      statusIcon = LucideIcons.checkCircle;
    } else if (maintenance.status == 'Atenção') {
      statusColor = AppColors.statusWarning;
      statusIcon = LucideIcons.alertCircle;
    } else {
      statusColor = AppColors.statusCritical;
      statusIcon = LucideIcons.alertTriangle;
    }

    final remainingKm = maintenance.remainingKm;
    final remainingLabel = remainingKm <= 0
        ? 'Troca recomendada agora'
        : '${NumberFormat('#,###').format(remainingKm)} km restantes';

    final isAlert = maintenance.status != 'OK';
    final isOil = maintenance.id == 'oil' ||
        maintenance.partName.toLowerCase().contains('óleo') ||
        maintenance.partName.toLowerCase().contains('oleo');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAlert
            ? Color.alphaBlend(statusColor.withOpacity(0.08), theme.cardColor)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withOpacity(isAlert ? 0.55 : 0.22),
          width: isAlert ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isAlert
                ? statusColor.withOpacity(0.12)
                : theme.shadowColor.withOpacity(0.06),
            blurRadius: isAlert ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maintenance.partName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOil && isAlert
                          ? '${maintenance.category} • prioridade'
                          : maintenance.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOil && isAlert
                            ? statusColor
                            : theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                        fontWeight:
                            isOil && isAlert ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isAlert ? 0.28 : 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: statusColor,
                    width: isAlert ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  maintenance.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.activity,
                      size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    'Saúde: ${(maintenance.healthPercentage * 100).round()}%',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(LucideIcons.mapPin,
                      size: 14,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    remainingLabel,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: maintenance.healthPercentage,
              minHeight: 8,
              backgroundColor: statusColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _kmInfo(
                  theme,
                  icon: LucideIcons.clock,
                  label: 'Última troca',
                  value: maintenance.lastChangeKm == 0
                      ? '—'
                      : '${NumberFormat('#,###').format(maintenance.lastChangeKm)} km',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: theme.dividerColor,
              ),
              Expanded(
                child: _kmInfo(
                  theme,
                  icon: LucideIcons.target,
                  label: 'Ciclo',
                  value:
                      '${NumberFormat('#,###').format(maintenance.recommendedChangeKm)} km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _markDoneFlow(bike, maintenance),
                  icon: const Icon(LucideIcons.checkCheck, size: 16),
                  label: const Text('Marcar como feita'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusOk,
                    side: BorderSide(
                      color: AppColors.statusOk.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (maintenance.status != 'OK')
            _buildPartnerSuggestion(maintenance, theme),
        ],
      ),
    );
  }

  Widget _kmInfo(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 12,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerSuggestion(Maintenance maintenance, ThemeData theme) {
    const double userLatitude = -23.5505;
    const double userLongitude = -46.6333;

    final partners = MockDataService.getMockPartners();
    final relevantPartners = partners.where((partner) {
      final hasSpecialty = partner.specialties.any((specialty) =>
          specialty.toLowerCase() == maintenance.category.toLowerCase());
      final hasPromotion = partner.activePromotions.any((promo) =>
          promo.category?.toLowerCase() == maintenance.category.toLowerCase());
      return (hasSpecialty || hasPromotion) &&
          partner.activePromotions.isNotEmpty;
    }).toList();

    if (relevantPartners.isEmpty) return const SizedBox.shrink();

    relevantPartners.sort((a, b) => a
        .distanceTo(userLatitude, userLongitude)
        .compareTo(b.distanceTo(userLatitude, userLongitude)));

    final nearestPartner = relevantPartners.first;
    final distance = nearestPartner.distanceTo(userLatitude, userLongitude);
    final relevantPromotion = nearestPartner.activePromotions.firstWhere(
      (promo) =>
          promo.category?.toLowerCase() == maintenance.category.toLowerCase(),
      orElse: () => nearestPartner.activePromotions.first,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.racingOrange.withOpacity(0.18),
              AppColors.racingOrange.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.racingOrange.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.store,
                    color: AppColors.racingOrange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${nearestPartner.type == PartnerType.store ? "Loja" : "Oficina"} ${nearestPartner.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            if (relevantPromotion.discountPercentage > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${relevantPromotion.discountPercentage.toInt()}% de desconto via Giro Certo',
                style: TextStyle(
                  color: AppColors.racingOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => VoucherModal(
                      partner: nearestPartner,
                      promotion: relevantPromotion,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.racingOrange,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Ver Oferta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
