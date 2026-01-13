import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/colors.dart';

class PilotProfileScreen extends StatelessWidget {
  final Function(String profile) onSelectProfile;

  const PilotProfileScreen({
    super.key,
    required this.onSelectProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGrafite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'Perfil de Pilotagem',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Como você usa sua moto?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildProfileCard(
                      icon: LucideIcons.calendar,
                      title: 'Fim de Semana',
                      subtitle: 'Casual',
                      color: AppColors.racingOrange,
                      onTap: () => onSelectProfile('Fim de Semana'),
                    ),
                    _buildProfileCard(
                      icon: LucideIcons.mapPin,
                      title: 'Urbano',
                      subtitle: 'Diário',
                      color: AppColors.neonGreen,
                      onTap: () => onSelectProfile('Urbano'),
                    ),
                    _buildProfileCard(
                      icon: LucideIcons.package,
                      title: 'Trabalho',
                      subtitle: 'Delivery',
                      color: AppColors.statusWarning,
                      onTap: () => onSelectProfile('Trabalho'),
                    ),
                    _buildProfileCard(
                      icon: LucideIcons.trophy,
                      title: 'Pista',
                      subtitle: 'Racing',
                      color: AppColors.alertRed,
                      onTap: () => onSelectProfile('Pista'),
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

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
