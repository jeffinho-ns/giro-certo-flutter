import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/theme_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import 'image_diagnostic_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            const ModernHeader(
              title: 'Configurações',
              showBackButton: true,
            ),
            
            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção de Tema
                    Text(
                      'Tema',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Card de seleção de tema claro/escuro
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
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
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      themeProvider.primaryColor,
                                      themeProvider.primaryLightColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isDark ? LucideIcons.moon : LucideIcons.sun,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Modo',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Escolha entre tema claro ou escuro',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Opções de tema
                          Row(
                            children: [
                              Expanded(
                                child: _buildThemeOption(
                                  context: context,
                                  theme: theme,
                                  title: 'Claro',
                                  icon: LucideIcons.sun,
                                  isSelected: !themeProvider.isDarkMode,
                                  color: themeProvider.primaryColor,
                                  onTap: () {
                                    themeProvider.setTheme(AppThemeMode.light);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildThemeOption(
                                  context: context,
                                  theme: theme,
                                  title: 'Escuro',
                                  icon: LucideIcons.moon,
                                  isSelected: themeProvider.isDarkMode,
                                  color: themeProvider.primaryColor,
                                  onTap: () {
                                    themeProvider.setTheme(AppThemeMode.dark);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Diagnóstico de imagens
                    ListTile(
                      leading: Icon(LucideIcons.bug, color: themeProvider.primaryColor),
                      title: const Text('Diagnóstico de Imagens'),
                      subtitle: const Text('Ver o que a API retorna (posts, stories)'),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ImageDiagnosticScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Seção de Cores
                    Text(
                      'Cor do Tema',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Card de seleção de cor
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
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
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      themeProvider.primaryColor,
                                      themeProvider.primaryLightColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  LucideIcons.palette,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cor Principal',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Personalize a cor do app',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Opções de cores
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildColorOption(
                                context: context,
                                theme: theme,
                                color: AppThemeColor.orange,
                                isSelected: themeProvider.themeColor == AppThemeColor.orange,
                                primaryColor: AppColors.racingOrange,
                                onTap: () {
                                  themeProvider.setThemeColor(AppThemeColor.orange);
                                },
                              ),
                              _buildColorOption(
                                context: context,
                                theme: theme,
                                color: AppThemeColor.blue,
                                isSelected: themeProvider.themeColor == AppThemeColor.blue,
                                primaryColor: const Color(0xFF5C9FD4), // Azul suave
                                onTap: () {
                                  themeProvider.setThemeColor(AppThemeColor.blue);
                                },
                              ),
                              _buildColorOption(
                                context: context,
                                theme: theme,
                                color: AppThemeColor.green,
                                isSelected: themeProvider.themeColor == AppThemeColor.green,
                                primaryColor: const Color(0xFF6BAF7A), // Verde suave
                                onTap: () {
                                  themeProvider.setThemeColor(AppThemeColor.green);
                                },
                              ),
                              _buildColorOption(
                                context: context,
                                theme: theme,
                                color: AppThemeColor.purple,
                                isSelected: themeProvider.themeColor == AppThemeColor.purple,
                                primaryColor: const Color(0xFF9A7BAF), // Roxo suave
                                onTap: () {
                                  themeProvider.setThemeColor(AppThemeColor.purple);
                                },
                              ),
                              _buildColorOption(
                                context: context,
                                theme: theme,
                                color: AppThemeColor.red,
                                isSelected: themeProvider.themeColor == AppThemeColor.red,
                                primaryColor: const Color(0xFFD67B7B), // Vermelho suave
                                onTap: () {
                                  themeProvider.setThemeColor(AppThemeColor.red);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Informações adicionais
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeProvider.primaryColor.withOpacity(0.1),
                            themeProvider.primaryColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: themeProvider.primaryColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.info,
                              color: themeProvider.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'As preferências serão salvas automaticamente e aplicadas imediatamente.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : theme.iconTheme.color,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption({
    required BuildContext context,
    required ThemeData theme,
    required AppThemeColor color,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.7),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isSelected
            ? const Center(
                child: Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 24,
                ),
              )
            : null,
      ),
    );
  }
}
