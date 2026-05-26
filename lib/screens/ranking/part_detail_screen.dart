import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/part.dart';
import '../../utils/colors.dart';
import '../../widgets/api_image.dart';
import '../../widgets/modern_header.dart';

/// Detalhe completo de uma peça no Ranking: descrição, compatibilidade,
/// avaliações sumarizadas e CTA de "Ver lojas com esta peça".
class PartDetailScreen extends StatelessWidget {
  final Part part;
  final int? rank;
  const PartDetailScreen({super.key, required this.part, this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Detalhe da peça',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.racingOrange.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: part.imageUrl != null && part.imageUrl!.isNotEmpty
                            ? ApiImage(url: part.imageUrl!, fit: BoxFit.cover)
                            : Icon(LucideIcons.cog,
                                size: 80, color: AppColors.racingOrange),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (rank != null && rank! <= 3) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.racingOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.trophy,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Top $rank',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Text(
                            part.category,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      part.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Marca • ${part.brand}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.racingOrange.withOpacity(0.15),
                            AppColors.racingOrange.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _stat(
                              theme,
                              icon: LucideIcons.star,
                              label: 'Nota média',
                              value: part.rating.toStringAsFixed(1),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                          Expanded(
                            child: _stat(
                              theme,
                              icon: LucideIcons.users,
                              label: 'Avaliações',
                              value: part.reviewCount.toString(),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: theme.dividerColor.withOpacity(0.5),
                          ),
                          Expanded(
                            child: _stat(
                              theme,
                              icon: LucideIcons.bike,
                              label: 'Compatíveis',
                              value: part.compatibleModels.length.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Sobre a peça',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(part.description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    Text('Modelos compatíveis',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: part.compatibleModels
                          .map((m) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: theme.dividerColor),
                                ),
                                child: Text(
                                  m,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Procura por parceiros com esta peça em breve.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.shoppingBag),
                        label: const Text('Ver lojas com esta peça'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.racingOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(ThemeData theme,
      {required IconData icon,
      required String label,
      required String value}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.racingOrange),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
