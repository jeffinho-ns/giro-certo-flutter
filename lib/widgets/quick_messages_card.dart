import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/colors.dart';

/// Card flutuante semi-transparente com blur (Glassmorphism) para últimas notificações/alertas.
class QuickMessagesCard extends StatelessWidget {
  final List<QuickMessageItem> items;
  final VoidCallback? onSeeAll;
  final int maxVisible;

  const QuickMessagesCard({
    super.key,
    this.items = const [],
    this.onSeeAll,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = items.take(maxVisible).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180), // Menor que metade da tela (típico ~400px)
          padding: const EdgeInsets.all(8), // Reduzido de 16 para 8 (50%)
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8, // Reduzido de 16 para 8 (50%)
                offset: const Offset(0, 2), // Reduzido de 4 para 2 (50%)
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.bell,
                    size: 12, // Reduzido de 16 para 12 (75% para manter legibilidade)
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                  ),
                  const SizedBox(width: 4), // Reduzido de 8 para 4 (50%)
                  Flexible(
                    child: Text(
                      'Mensagens Rápidas',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        fontSize: 11, // Reduzido proporcionalmente
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6), // Reduzido de 12 para 6 (50%)
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4), // Reduzido de 8 para 4 (50%)
                  child: Text(
                    'Nenhum alerta recente',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 10, // Reduzido proporcionalmente
                    ),
                  ),
                )
              else
                ...visible.map((item) => _MessageRow(
                      icon: item.icon,
                      iconColor: item.color ?? AppColors.racingOrange,
                      title: item.title,
                      subtitle: item.subtitle,
                      theme: theme,
                    )),
              if (onSeeAll != null && items.isNotEmpty) ...[
                const SizedBox(height: 4), // Reduzido de 8 para 4 (50%)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      color: AppColors.racingOrange.withOpacity(0.9),
                      fontSize: 10, // Reduzido de 12 para 10
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class QuickMessageItem {
  final IconData icon;
  final Color? color;
  final String title;
  final String? subtitle;

  const QuickMessageItem({
    required this.icon,
    this.color,
    required this.title,
    this.subtitle,
  });
}

class _MessageRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final ThemeData theme;

  const _MessageRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5), // Reduzido de 10 para 5 (50%)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3), // Reduzido de 5 para 3 (60% para manter visibilidade)
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4), // Reduzido de 6 para 4
            ),
            child: Icon(icon, size: 10, color: iconColor.withOpacity(0.9)), // Reduzido de 14 para 10
          ),
          const SizedBox(width: 5), // Reduzido de 10 para 5 (50%)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 10, // Reduzido de 12 para 10
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 1), // Reduzido de 2 para 1 (50%)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9, // Reduzido de 11 para 9
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
