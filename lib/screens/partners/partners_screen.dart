import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/partner.dart';
import '../../services/mock_data_service.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import 'voucher_modal.dart';
import 'partner_detail_modal.dart';

// Painter customizado para criar padrão de mapa estilo Google Maps
class _MapPatternPainter extends CustomPainter {
  final ThemeData theme;
  final int partnerCount;
  
  _MapPatternPainter({required this.theme, required this.partnerCount});
  
  @override
  void paint(Canvas canvas, Size size) {
    final isDark = theme.brightness == Brightness.dark;
    
    // Fundo do mapa (cor base estilo Google Maps)
    final backgroundPaint = Paint()
      ..color = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8EAED)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // Áreas verdes (parques/squares)
    final greenPaint = Paint()
      ..color = isDark ? const Color(0xFF2D4A2D) : const Color(0xFFC8E6C9)
      ..style = PaintingStyle.fill;
    
    // Desenhar alguns blocos verdes (parques)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.15, size.width * 0.25, size.height * 0.2),
        const Radius.circular(8),
      ),
      greenPaint,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.7, size.height * 0.5, size.width * 0.2, size.height * 0.25),
        const Radius.circular(8),
      ),
      greenPaint,
    );
    
    // Ruas secundárias (linhas finas)
    final minorStreetPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.5;
    
    const minorStreetSpacing = 60.0;
    for (double x = 0; x < size.width; x += minorStreetSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        minorStreetPaint,
      );
    }
    for (double y = 0; y < size.height; y += minorStreetSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        minorStreetPaint,
      );
    }
    
    // Ruas principais (linhas mais grossas e claras)
    final majorStreetPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12)
      ..strokeWidth = 3;
    
    // Rua horizontal principal
    final centerY = size.height * 0.4;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      majorStreetPaint,
    );
    
    // Rua vertical principal
    final centerX = size.width / 2;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      majorStreetPaint,
    );
    
    // Ruas diagonais secundárias
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width, size.height * 0.75),
      minorStreetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(0, size.height * 0.75),
      minorStreetPaint,
    );
    
    // Quadras/Blocos (retângulos preenchidos)
    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF2A2A2A) : Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // Desenhar alguns blocos
    final blockSize = 80.0;
    for (double x = 0; x < size.width - blockSize; x += blockSize * 1.5) {
      for (double y = 0; y < size.height - blockSize; y += blockSize * 1.5) {
        // Pular áreas verdes
        if ((x < size.width * 0.35 && y < size.height * 0.35) ||
            (x > size.width * 0.7 && y > size.height * 0.5)) {
          continue;
        }
        
        canvas.drawRect(
          Rect.fromLTWH(x, y, blockSize * 0.9, blockSize * 0.9),
          blockPaint,
        );
      }
    }
    
    // Grade de referência sutil
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)
      ..strokeWidth = 0.5;
    
    const gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_MapPatternPainter oldDelegate) => false;
}

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Lojas', 'Mecânicos', 'Mais Próximo', 'Melhor Avaliação'];
  late TabController _tabController;
  
  // Localização simulada do usuário (São Paulo centro)
  final double _userLatitude = -23.5505;
  final double _userLongitude = -46.6333;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partners = MockDataService.getMockPartners();
    
    // Ordenar por distância quando filtro "Mais Próximo" estiver selecionado
    final sortedPartners = () {
      if (_selectedFilter == 'Mais Próximo') {
        final list = List<Partner>.from(partners);
        list.sort((a, b) => a.distanceTo(_userLatitude, _userLongitude)
            .compareTo(b.distanceTo(_userLatitude, _userLongitude)));
        return list;
      } else if (_selectedFilter == 'Melhor Avaliação') {
        final list = List<Partner>.from(partners);
        list.sort((a, b) => b.rating.compareTo(a.rating));
        return list;
      }
      return partners;
    }();

    // Filtrar por tipo
    final filteredPartners = _selectedFilter == 'Lojas'
        ? sortedPartners.where((p) => p.type == PartnerType.store).toList()
        : _selectedFilter == 'Mecânicos'
            ? sortedPartners.where((p) => p.type == PartnerType.mechanic).toList()
            : sortedPartners;

    // Parceiros de confiança
    final trustedPartners = filteredPartners.where((p) => p.isTrusted).toList();

    // Encontrar menores valores (simulado - peças comuns)
    final bestDeals = _getBestDeals(filteredPartners);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const ModernHeader(
            title: 'Parceiros & Mecânicos',
            showBackButton: false,
          ),
          
          // Filtros
          _buildFilterChips(theme),
          
          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.racingOrange,
            labelColor: AppColors.racingOrange,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            tabs: const [
              Tab(text: 'Mapa'),
              Tab(text: 'Menores Valores'),
              Tab(text: 'Mecânicos de Confiança'),
            ],
          ),
          
          // Conteúdo
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Mapa
                _buildMapView(filteredPartners, theme),
                // Menores Valores
                _buildBestDealsView(bestDeals, theme),
                // Mecânicos de Confiança
                _buildTrustedMechanicsView(trustedPartners, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppColors.racingOrange.withOpacity(0.2),
              checkmarkColor: AppColors.racingOrange,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.racingOrange
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.racingOrange
                    : theme.dividerColor,
                width: 1.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(List<Partner> partners, ThemeData theme) {
    return Column(
      children: [
        // Mapa visual melhorado
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                ),
                child: Stack(
                  children: [
                    // Padrão de mapa estilizado
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _MapPatternPainter(
                        theme: theme,
                        partnerCount: partners.length,
                      ),
                    ),
                
                    // Pins dos parceiros
                    ...partners.map((partner) {
                      final distance = partner.distanceTo(_userLatitude, _userLongitude);
                      // Posição normalizada para o centro da tela
                      final screenWidth = constraints.maxWidth;
                      final screenHeight = constraints.maxHeight;
                      final latOffset = ((partner.latitude - _userLatitude) * 50000).clamp(-screenWidth * 0.3, screenWidth * 0.3);
                      final lngOffset = ((partner.longitude - _userLongitude) * 50000).clamp(-screenWidth * 0.3, screenWidth * 0.3);
                      
                      return Positioned(
                        left: (screenWidth / 2) + lngOffset - 20,
                        top: (screenHeight * 0.4) + latOffset - 20,
                        child: GestureDetector(
                          onTap: () => _showPartnerDetail(partner),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: partner.type == PartnerType.store
                                      ? AppColors.racingOrange
                                      : AppColors.neonGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (partner.type == PartnerType.store
                                          ? AppColors.racingOrange
                                          : AppColors.neonGreen).withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  partner.type == PartnerType.store
                                      ? LucideIcons.store
                                      : LucideIcons.wrench,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${distance.toStringAsFixed(1)}km',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    
                    // Localização do usuário (centro)
                    Positioned(
                      left: constraints.maxWidth / 2 - 15,
                      top: constraints.maxHeight * 0.4 - 15,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.mapPin,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Lista de parceiros abaixo do mapa (sem menu, então pode ser maior)
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 20,
                      color: AppColors.racingOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Parceiros próximos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${partners.length} encontrados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    final partner = partners[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildPartnerCard(partner, theme, isCompact: true),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestDealsView(List<Map<String, dynamic>> bestDeals, ThemeData theme) {
    if (bestDeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.tag,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma oferta encontrada',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: bestDeals.length,
      itemBuilder: (context, index) {
        final deal = bestDeals[index];
        final partner = deal['partner'] as Partner;
        final promotion = deal['promotion'] as Promotion;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildDealCard(partner, promotion, theme),
        );
      },
    );
  }

  Widget _buildTrustedMechanicsView(List<Partner> trustedPartners, ThemeData theme) {
    if (trustedPartners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shieldCheck,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum mecânico de confiança encontrado',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: trustedPartners.length,
      itemBuilder: (context, index) {
        final partner = trustedPartners[index];
        return _buildPartnerCard(partner, theme);
      },
    );
  }

  Widget _buildDealCard(Partner partner, Promotion promotion, ThemeData theme) {
    final distance = partner.distanceTo(_userLatitude, _userLongitude);
    
    return GestureDetector(
      onTap: () => _showVoucherModal(partner, promotion),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.racingOrange.withOpacity(0.15),
              AppColors.racingOrange.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.racingOrange.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.racingOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                LucideIcons.tag,
                color: AppColors.racingOrange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.description,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.store,
                        size: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          partner.name,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.racingOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${promotion.discountPercentage.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(Partner partner, ThemeData theme, {bool isCompact = false}) {
    final distance = partner.distanceTo(_userLatitude, _userLongitude);
    
    return GestureDetector(
      onTap: () => _showPartnerDetail(partner),
      child: Container(
        width: isCompact ? 260 : double.infinity,
        margin: EdgeInsets.only(bottom: isCompact ? 0 : 16),
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: partner.isTrusted
              ? Border.all(
                  color: AppColors.neonGreen.withOpacity(0.5),
                  width: 2,
                )
              : Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: partner.type == PartnerType.store
                        ? AppColors.racingOrange.withOpacity(0.2)
                        : AppColors.neonGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    partner.type == PartnerType.store
                        ? LucideIcons.store
                        : LucideIcons.wrench,
                    color: partner.type == PartnerType.store
                        ? AppColors.racingOrange
                        : AppColors.neonGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              partner.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (partner.isTrusted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.neonGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.shieldCheck,
                                    size: 12,
                                    color: AppColors.neonGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verificado',
                                    style: TextStyle(
                                      color: AppColors.neonGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.star,
                            size: 14,
                            color: AppColors.racingOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            partner.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isCompact) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      partner.address,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ...partner.specialties.take(isCompact ? 2 : 3).map((specialty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.racingOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.racingOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ],
            ),
            if (partner.activePromotions.isNotEmpty && !isCompact) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.racingOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.tag,
                      size: 16,
                      color: AppColors.racingOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        partner.activePromotions.first.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.racingOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (partner.activePromotions.isNotEmpty && isCompact) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    LucideIcons.tag,
                    size: 12,
                    color: AppColors.racingOrange,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      partner.activePromotions.first.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.racingOrange,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getBestDeals(List<Partner> partners) {
    final deals = <Map<String, dynamic>>[];
    for (final partner in partners) {
      for (final promotion in partner.activePromotions) {
        deals.add({
          'partner': partner,
          'promotion': promotion,
        });
      }
    }
    // Ordenar por maior desconto
    deals.sort((a, b) => (b['promotion'] as Promotion).discountPercentage
        .compareTo((a['promotion'] as Promotion).discountPercentage));
    return deals;
  }

  void _showPartnerDetail(Partner partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerDetailModal(partner: partner),
    );
  }

  void _showVoucherModal(Partner partner, Promotion promotion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoucherModal(
        partner: partner,
        promotion: promotion,
      ),
    );
  }
}
