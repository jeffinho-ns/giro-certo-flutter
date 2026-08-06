import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../models/community.dart';
import '../../models/community_type.dart';
import '../../utils/colors.dart';
import '../../widgets/api_image.dart';
import '../../widgets/modern_header.dart';
import '../chat/chat_screen.dart';

/// Detalhe de uma comunidade: descrição, regras, botão para abrir o feed
/// (que reusa o `ChatScreen` com a aba de comunidade).
class CommunityDetailScreen extends StatelessWidget {
  final Community community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sem locale 'pt_BR' — evita LocaleDataException (tela branca) se o locale
    // não foi inicializado com initializeDateFormatting.
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Comunidade',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.racingOrange.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: community.imageUrl != null &&
                                  community.imageUrl!.isNotEmpty
                              ? ApiImage(
                                  url: community.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Icon(LucideIcons.users,
                                  color: AppColors.racingOrange, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.racingOrange
                                      .withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  community.type.label,
                                  style: TextStyle(
                                    color: AppColors.racingOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _stat(
                              theme,
                              icon: LucideIcons.user,
                              label: 'Membros',
                              value: community.memberCount.toString(),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: theme.dividerColor.withOpacity(0.4),
                          ),
                          Expanded(
                            child: _stat(
                              theme,
                              icon: LucideIcons.calendar,
                              label: 'Criada em',
                              value: dateFmt.format(community.createdAt),
                            ),
                          ),
                          if (community.zone != null) ...[
                            Container(
                              width: 1,
                              height: 40,
                              color: theme.dividerColor.withOpacity(0.4),
                            ),
                            Expanded(
                              child: _stat(
                                theme,
                                icon: LucideIcons.mapPin,
                                label: 'Zona',
                                value: community.zone!,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sobre',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      community.description.isEmpty
                          ? 'Esta comunidade ainda não tem uma descrição.'
                          : community.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Regras da comunidade',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _rule(theme, 'Respeite os outros pilotos.'),
                    _rule(theme, 'Sem spam, anúncios sem autorização ou conteúdo ofensivo.'),
                    _rule(theme, 'Reporte comportamento abusivo via menu do post.'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChatScreen(),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.messageCircle),
                        label: const Text('Abrir conversa'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.racingOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Já és membro desta comunidade.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.checkCircle),
                        label: const Text('Membro'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusOk,
                          side: BorderSide(
                            color: AppColors.statusOk.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.racingOrange, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _rule(ThemeData theme, String rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.checkCircle,
              size: 14, color: AppColors.racingOrange),
          const SizedBox(width: 8),
          Expanded(child: Text(rule, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
