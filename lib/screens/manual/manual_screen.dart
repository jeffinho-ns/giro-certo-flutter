import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/colors.dart';

class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  String? _selectedPart;

  final Map<String, Map<String, String>> _partsInfo = {
    'Motor': {
      'title': 'Motor',
      'description': 'O motor é o coração da sua moto. Mantenha o óleo sempre no nível correto e troque conforme as especificações do fabricante. Monitore temperatura e ruídos anormais.',
      'icon': 'settings',
    },
    'Suspensão': {
      'title': 'Suspensão',
      'description': 'A suspensão é crucial para conforto e segurança. Verifique vazamentos de óleo, pressão e regulagem conforme o peso do piloto e tipo de uso.',
      'icon': 'zap',
    },
    'Elétrica': {
      'title': 'Sistema Elétrico',
      'description': 'Bateria, alternador e sistema de ignição. Verifique terminais da bateria, fiação e carga do sistema. Mantenha a bateria sempre carregada.',
      'icon': 'battery',
    },
    'Freios': {
      'title': 'Sistema de Freios',
      'description': 'Pastilhas, discos e fluido de freio. Substitua pastilhas quando desgastadas e troque o fluido a cada 2 anos ou conforme recomendação.',
      'icon': 'shield',
    },
    'Transmissão': {
      'title': 'Transmissão',
      'description': 'Corrente, pinhão e coroa. Mantenha lubrificada e ajustada. Verifique tensão e alinhamento regularmente.',
      'icon': 'link',
    },
    'Pneus': {
      'title': 'Pneus',
      'description': 'Verifique pressão semanalmente, profundidade do sulco (mínimo 1.6mm) e sinais de desgaste irregular. Rotacione conforme necessário.',
      'icon': 'circle',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGrafite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manual Interativo'),
      ),
      body: _selectedPart == null ? _buildBikeDiagram() : _buildPartDetail(_selectedPart!),
    );
  }

  Widget _buildBikeDiagram() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Knowledge Hub',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em uma parte para saber mais',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          
          // Diagrama simplificado da moto
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: AppColors.darkGray,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Desenho simplificado usando ícones e textos
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPartButton('Pneus', 0.2, 0.1),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPartButton('Freios', 0.15, 0.3),
                          _buildPartButton('Motor', 0.2, 0.4),
                          _buildPartButton('Suspensão', 0.15, 0.3),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPartButton('Transmissão', 0.15, 0.3),
                          _buildPartButton('Elétrica', 0.15, 0.3),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Lista de partes
          ..._partsInfo.keys.map((partKey) => _buildPartListItem(partKey)),
        ],
      ),
    );
  }

  Widget _buildPartButton(String part, double widthFactor, double heightFactor) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPart = part),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.racingOrange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.racingOrange, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForPart(part),
              color: AppColors.racingOrange,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              part,
              style: const TextStyle(
                color: AppColors.racingOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartListItem(String part) {
    final info = _partsInfo[part]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => setState(() => _selectedPart = part),
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: AppColors.darkGray,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.racingOrange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForPart(part),
            color: AppColors.racingOrange,
          ),
        ),
        title: Text(
          info['title']!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          LucideIcons.chevronRight,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPartDetail(String part) {
    final info = _partsInfo[part]!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => setState(() => _selectedPart = null),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkGray,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.racingOrange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForPart(part),
                    color: AppColors.racingOrange,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  info['title']!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  info['description']!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPart(String part) {
    switch (part) {
      case 'Motor':
        return LucideIcons.settings;
      case 'Suspensão':
        return LucideIcons.zap;
      case 'Elétrica':
        return LucideIcons.battery;
      case 'Freios':
        return LucideIcons.shield;
      case 'Transmissão':
        return LucideIcons.link;
      case 'Pneus':
        return LucideIcons.circle;
      default:
        return LucideIcons.wrench;
    }
  }
}
