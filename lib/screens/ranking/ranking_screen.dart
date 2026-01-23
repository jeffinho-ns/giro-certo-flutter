import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../services/mock_data_service.dart';
import '../../models/part.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String _selectedCategory = 'Todas';

  final List<String> _categories = [
    'Todas',
    'Performance',
    'Estética',
    'Conforto',
    'Custo-Benefício',
  ];

  @override
  Widget build(BuildContext context) {
    var parts = MockDataService.getMockParts();
    
    if (_selectedCategory != 'Todas') {
      parts = parts.where((part) => part.category == _selectedCategory).toList();
    }
    
    parts.sort((a, b) => b.rating.compareTo(a.rating));
    parts = parts.take(5).toList();

    final theme = Theme.of(context);
    
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          const ModernHeader(
            title: 'Ranking de Peças',
            showBackButton: false,
          ),
          
          // Filtros
          Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: AppColors.racingOrange,
                      backgroundColor: theme.cardColor,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.racingOrange
                            : theme.dividerColor,
                        width: isSelected ? 2 : 1.5,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Lista de peças
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: parts.length,
              itemBuilder: (context, index) {
                final part = parts[index];
                return _buildModernPartCard(part, index + 1, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPartCard(Part part, int rank, ThemeData theme) {
    final isTopRank = rank <= 3;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isTopRank
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.racingOrange.withOpacity(0.15),
                  AppColors.racingOrange.withOpacity(0.05),
                ],
              )
            : null,
        color: isTopRank ? null : theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTopRank
              ? AppColors.racingOrange.withOpacity(0.4)
              : theme.dividerColor,
          width: isTopRank ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopRank
                ? AppColors.racingOrange.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isTopRank ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Badge de ranking
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isTopRank
                        ? LinearGradient(
                            colors: [
                              AppColors.racingOrange,
                              AppColors.racingOrangeLight,
                            ],
                          )
                        : null,
                    color: isTopRank ? null : theme.cardColor,
                    shape: BoxShape.circle,
                    border: isTopRank
                        ? null
                        : Border.all(
                            color: theme.dividerColor,
                            width: 1.5,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: isTopRank ? Colors.white : theme.textTheme.bodyMedium?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        part.brand,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.racingOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.star,
                            color: AppColors.racingOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            part.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.racingOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${part.reviewCount} avaliações',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.racingOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                part.category,
                style: TextStyle(
                  color: AppColors.racingOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              part.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
