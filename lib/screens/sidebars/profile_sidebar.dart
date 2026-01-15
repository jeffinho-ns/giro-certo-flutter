import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/colors.dart';
import '../settings/settings_screen.dart';

class ProfileSidebar extends StatelessWidget {
  const ProfileSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final user = appState.user;
    final bike = appState.bike;
    final theme = Theme.of(context);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Header do perfil com gradiente
              Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.racingOrange,
                      AppColors.racingOrangeLight,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Foto do perfil
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: user?.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                user?.name[0].toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Piloto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Informações da moto
              if (bike != null)
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
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
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.racingOrange,
                                  AppColors.racingOrangeLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.bike,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Minha Moto',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        theme: theme,
                        icon: LucideIcons.hash,
                        label: 'Placa',
                        value: bike.plate,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        theme: theme,
                        icon: LucideIcons.gauge,
                        label: 'Quilometragem',
                        value: '${bike.currentKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} km',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        theme: theme,
                        icon: LucideIcons.user,
                        label: 'Perfil',
                        value: user?.pilotProfile ?? 'N/A',
                      ),
                    ],
                  ),
                ),

              // Menu de opções
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildMenuItem(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.user,
                      title: 'Editar Perfil',
                      subtitle: 'Atualizar informações pessoais',
                      onTap: () {
                        Navigator.pop(context);
                        // Navegar para edição de perfil
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.bike,
                      title: 'Minha Garagem',
                      subtitle: 'Gerenciar motos cadastradas',
                      onTap: () {
                        Navigator.pop(context);
                        // Navegar para garagem
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.settings,
                      title: 'Configurações',
                      subtitle: 'Tema, cores e preferências',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.helpCircle,
                      title: 'Ajuda',
                      subtitle: 'Central de suporte',
                      onTap: () {
                        Navigator.pop(context);
                        // Navegar para ajuda
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    _buildMenuItem(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.logOut,
                      title: 'Sair',
                      subtitle: 'Fazer logout da conta',
                      color: AppColors.alertRed,
                      onTap: () {
                        Navigator.pop(context);
                        // Implementar logout
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.racingOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.racingOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.racingOrange;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      itemColor.withOpacity(0.2),
                      itemColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: itemColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: itemColor == AppColors.alertRed ? itemColor : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: theme.iconTheme.color?.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
