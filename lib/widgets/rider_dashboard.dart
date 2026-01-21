import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/rider_stats.dart';
import '../utils/colors.dart';
import '../providers/theme_provider.dart';

class RiderDashboard extends StatelessWidget {
  final RiderStats stats;

  const RiderDashboard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card de ganhos hoje com meta
          _buildTodayEarningsCard(theme, isDark, primaryColor),
          const SizedBox(height: 16),
          
          // Resumo de ganhos (semana/mês/total)
          _buildEarningsSummary(theme, primaryColor),
          const SizedBox(height: 16),
          
          // Estatísticas gerais
          _buildStatsGrid(theme, primaryColor),
          const SizedBox(height: 16),
          
          // Corridas ativas
          if (stats.activeDeliveries > 0) ...[
            _buildActiveDeliveriesHeader(theme, primaryColor),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayEarningsCard(ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.2),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ganhos de Hoje',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${stats.todayEarnings.toStringAsFixed(2)}',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.dollarSign,
                  color: primaryColor,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Meta diária
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meta do Dia',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${stats.dailyGoal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                stats.goalStatus,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.dailyGoalProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                stats.dailyGoalProgress >= 1.0 
                      ? AppColors.neonGreen 
                      : primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats.dailyGoalPercentage.toStringAsFixed(1)}% da meta',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              if (stats.dailyGoalProgress < 1.0)
                Text(
                  'Faltam R\$ ${(stats.dailyGoal - stats.todayEarnings).toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
            ],
          ),
          
          // Previsão do dia
          if (stats.todayEarnings > 0 && stats.dailyGoalProgress < 1.0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.trendingUp,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Previsão do dia: R\$ ${stats.projectedEarningsToday.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsSummary(ThemeData theme, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            theme,
            'Semana',
            'R\$ ${stats.weekEarnings.toStringAsFixed(2)}',
            '${stats.weekDeliveries} corridas',
            LucideIcons.calendar,
            primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            theme,
            'Mês',
            'R\$ ${stats.monthEarnings.toStringAsFixed(2)}',
            '${stats.monthDeliveries} corridas',
            LucideIcons.calendarDays,
            primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            theme,
            'Total',
            'R\$ ${stats.totalEarnings.toStringAsFixed(2)}',
            '${stats.totalDeliveries} corridas',
            LucideIcons.trophy,
            AppColors.neonGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Avaliação',
                  stats.averageRating > 0 
                    ? '${stats.averageRating.toStringAsFixed(1)} ⭐'
                    : 'N/A',
                  LucideIcons.star,
                  primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Tempo Médio',
                  stats.averageDeliveryTimeFormatted,
                  LucideIcons.clock,
                  primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Km Percorridos',
                  '${stats.totalKmTraveled} km',
                  LucideIcons.mapPin,
                  primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Corridas Ativas',
                  '${stats.activeDeliveries}',
                  LucideIcons.package,
                  primaryColor,
                ),
              ),
            ],
          ),
          if (stats.todayDeliveries > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Ganho Médio',
                    'R\$ ${stats.averageEarningPerDelivery.toStringAsFixed(2)}',
                    LucideIcons.dollarSign,
                    primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDeliveriesHeader(ThemeData theme, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Corridas Ativas (${stats.activeDeliveries})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Em andamento',
            style: TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
