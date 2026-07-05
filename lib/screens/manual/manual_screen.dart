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
  String? _selectedGuide;

  final Map<String, Map<String, String>> _beginnerGuides = {
    'Equipamento': {
      'title': 'Equipamento',
      'description':
          'Antes de sair, confira o essencial: capacete certificado e bem ajustado, luvas, jaqueta com proteção, calça resistente e calçado fechado. Em chuva, use capa e evite visor embaciado. Nunca ande sem capacete — é o item que mais salva vidas.',
      'tips':
          '• Capacete: fivela fechada e sem folga\n• Luvas: aderência no manete\n• Luzes e setas funcionando\n• Retrovisores limpos e alinhados',
    },
    'Postura': {
      'title': 'Postura',
      'description':
          'Sente-se ereto, ombros relaxados e olhar longe, não só no asfalto à frente. Pés nas pedaleiras, joelhos levemente fechados no tanque. Cotovelos flexíveis para absorver solavancos. Uma boa postura reduz cansaço e melhora o controle.',
      'tips':
          '• Olhar para onde quer ir\n• Braços sem travar o guidão\n• Peso distribuído nos pés\n• Pausas a cada 1–2 h em viagens longas',
    },
    'Freios': {
      'title': 'Freios',
      'description':
          'Use freio dianteiro e traseiro juntos, com mais pressão no dianteiro (cerca de 70%). Em emergência, aperte progressivamente — não de uma vez. Em piso molhado, reduza a força e aumente a distância. Pratique em local seguro até o movimento ficar natural.',
      'tips':
          '• Dianteiro + traseiro juntos\n• Pressão progressiva, sem travar\n• Mais espaço em chuva\n• Pastilhas e fluido em dia',
    },
    'Curvas': {
      'title': 'Curvas',
      'description':
          'Reduza a velocidade antes da curva, nunca no meio. Olhe para a saída, incline o corpo com a moto e mantenha aceleração estável. Evite frear forte inclinado. Em curvas fechadas, entre por fora e saia por dentro quando for seguro.',
      'tips':
          '• Freie antes de inclinar\n• Olhe a saída da curva\n• Aceleração suave e constante\n• Não olhe para o obstáculo — olhe o caminho livre',
    },
    'Manutenção básica': {
      'title': 'Manutenção básica',
      'description':
          'Cheque semanalmente: pressão dos pneus, nível de óleo, luzes e tensão da corrente. Troque o óleo no intervalo do fabricante (ou use o alerta da garagem). Qualquer ruído, vibração ou luz no painel merece atenção antes de rodar.',
      'tips':
          '• Pneus: pressão semanal\n• Óleo: nível e troca no prazo\n• Corrente: lubrificada e ajustada\n• Use a Garagem e Manutenção do app para alertas',
    },
  };

  final Map<String, Map<String, String>> _partsInfo = {
    'Motor': {
      'title': 'Motor',
      'description':
          'O motor é o coração da sua moto. Mantenha o óleo sempre no nível correto e troque conforme as especificações do fabricante. Monitore temperatura e ruídos anormais.',
      'icon': 'settings',
    },
    'Suspensão': {
      'title': 'Suspensão',
      'description':
          'A suspensão é crucial para conforto e segurança. Verifique vazamentos de óleo, pressão e regulagem conforme o peso do piloto e tipo de uso.',
      'icon': 'zap',
    },
    'Elétrica': {
      'title': 'Sistema Elétrico',
      'description':
          'Bateria, alternador e sistema de ignição. Verifique terminais da bateria, fiação e carga do sistema. Mantenha a bateria sempre carregada.',
      'icon': 'battery',
    },
    'Freios': {
      'title': 'Sistema de Freios',
      'description':
          'Pastilhas, discos e fluido de freio. Substitua pastilhas quando desgastadas e troque o fluido a cada 2 anos ou conforme recomendação.',
      'icon': 'shield',
    },
    'Transmissão': {
      'title': 'Transmissão',
      'description':
          'Corrente, pinhão e coroa. Mantenha lubrificada e ajustada. Verifique tensão e alinhamento regularmente.',
      'icon': 'link',
    },
    'Pneus': {
      'title': 'Pneus',
      'description':
          'Verifique pressão semanalmente, profundidade do sulco (mínimo 1.6mm) e sinais de desgaste irregular. Rotacione conforme necessário.',
      'icon': 'circle',
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_selectedGuide != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _buildGuideDetail(_selectedGuide!, theme),
      );
    }
    if (_selectedPart != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _buildPartDetail(_selectedPart!, theme),
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _buildBikeDiagram(theme),
    );
  }

  Widget _buildBikeDiagram(ThemeData theme) {
    return CustomScrollView(
      slivers: [
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
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
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
                      'Guia do piloto',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Comece pelo básico e explore as partes da moto',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Para iniciantes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Equipamento, postura, freios, curvas e manutenção básica.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ..._beginnerGuides.keys.map(
                (key) => _buildGuideListItem(key, theme),
              ),

              const SizedBox(height: 28),
              Text(
                'Partes da moto',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque em uma parte para saber mais',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              Container(
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
                    _buildPartButton('Pneus'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPartButton('Freios'),
                        _buildPartButton('Motor'),
                        _buildPartButton('Suspensão'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPartButton('Transmissão'),
                        _buildPartButton('Elétrica'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Todas as partes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              ..._partsInfo.keys.map(
                (partKey) => _buildPartListItem(partKey, theme),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideListItem(String key, ThemeData theme) {
    final info = _beginnerGuides[key]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedGuide = key),
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
                    _getIconForGuide(key),
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
                        'Toque para ver o guia',
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

  Widget _buildPartButton(String part) {
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

  Widget _buildGuideDetail(String key, ThemeData theme) {
    final info = _beginnerGuides[key]!;
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
            onPressed: () => setState(() => _selectedGuide = null),
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
                padding: const EdgeInsets.all(28),
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
                      padding: const EdgeInsets.all(28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.racingOrange,
                            AppColors.racingOrangeLight,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForGuide(key),
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      info['description']!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checklist rápido',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      info['tips']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
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
                      decoration: const BoxDecoration(
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
                    Text(
                      info['description']!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
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

  IconData _getIconForGuide(String key) {
    switch (key) {
      case 'Equipamento':
        return LucideIcons.hardHat;
      case 'Postura':
        return LucideIcons.personStanding;
      case 'Freios':
        return LucideIcons.shield;
      case 'Curvas':
        return LucideIcons.cornerDownRight;
      case 'Manutenção básica':
        return LucideIcons.wrench;
      default:
        return LucideIcons.bookOpen;
    }
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
