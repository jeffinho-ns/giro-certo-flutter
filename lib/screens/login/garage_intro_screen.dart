import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/colors.dart';

class GarageIntroScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const GarageIntroScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGrafite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.racingOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.wrench,
                  size: 80,
                  color: AppColors.racingOrange,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Sua Garagem Digital',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'O Giro Certo monitora a saúde da sua moto baseado na quilometragem, alertando você sobre manutenções necessárias.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildFeature(
                LucideIcons.gauge,
                'Monitoramento em Tempo Real',
                'Acompanhe o estado das principais peças',
              ),
              const SizedBox(height: 24),
              _buildFeature(
                LucideIcons.bell,
                'Alertas Inteligentes',
                'Notificações quando a manutenção estiver próxima',
              ),
              const SizedBox(height: 24),
              _buildFeature(
                LucideIcons.barChart3,
                'Histórico Completo',
                'Registre todas as manutenções realizadas',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Configurar Garagem'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.racingOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.racingOrange, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
