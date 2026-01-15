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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _selectedPart == null ? _buildBikeDiagram(theme) : _buildPartDetail(_selectedPart!, theme),
    );
  }

  Widget _buildBikeDiagram(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Manual Interativo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
          ),
        ),
        
        // Conteúdo
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Builder(
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.racingOrange.withOpacity(0.12),
                          AppColors.racingOrange.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.racingOrange.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Knowledge Hub',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Toque em uma parte para saber mais',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Diagrama simplificado
              Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
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
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Lista de partes
              Text(
                'Todas as Partes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              ..._partsInfo.keys.map((partKey) => _buildPartListItem(partKey, theme)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPartButton(String part, double widthFactor, double heightFactor) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPart = part),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.racingOrange.withOpacity(0.2),
              AppColors.racingOrange.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.racingOrange,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.racingOrange.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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

  Widget _buildPartListItem(String part, ThemeData theme) {
    final info = _partsInfo[part]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPart = part),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.racingOrange.withOpacity(0.2),
                        AppColors.racingOrange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIconForPart(part),
                    color: AppColors.racingOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info['title']!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toque para ver detalhes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: theme.iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartDetail(String part, ThemeData theme) {
    final info = _partsInfo[part]!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => setState(() => _selectedPart = null),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              info['title']!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.racingOrange.withOpacity(0.15),
                      AppColors.racingOrange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.racingOrange.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.racingOrange,
                            AppColors.racingOrangeLight,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForPart(part),
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        return Text(
                          info['description']!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            height: 1.7,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
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
