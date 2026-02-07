import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../models/motorcycle_model.dart';
import '../../services/motorcycle_data_service.dart';

class GarageSetupScreen extends StatefulWidget {
  final Function({
    required MotorcycleModel motorcycle,
    String? resolvedImagePath,
    required String brand,
    required String model,
    required String plate,
    required int currentKm,
    required String oilType,
    required double frontTirePressure,
    required double rearTirePressure,
  }) onComplete;

  const GarageSetupScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<GarageSetupScreen> createState() => _GarageSetupScreenState();
}

class _GarageSetupScreenState extends State<GarageSetupScreen> {
  final _searchController = TextEditingController();
  MotorcycleModel? _selectedMotorcycle;
  String? _selectedBrand;
  String? _expandedBrand; // Acordeão: qual marca está expandida
  List<MotorcycleModel> _brandModels = [];
  List<String> _allBrands = [];
  String? _resolvedModelImagePath;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Obter todas as marcas únicas
    _allBrands = MotorcycleDataService.getAllBrands().toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _selectedBrand = null;
        _brandModels = [];
        _selectedMotorcycle = null;
        _expandedBrand = null;
      });
      return;
    }

    _isSearching = true;
    final results = MotorcycleDataService.searchMotorcycles(query);

    // Agrupar por marca
    final brands = results.map((m) => m.brand).toSet();
    String? foundBrand;

    // Verificar se a busca corresponde a uma marca
    for (final brand in brands) {
      if (brand.toLowerCase().contains(query.toLowerCase())) {
        foundBrand = brand;
        break;
      }
    }

    setState(() {
      if (foundBrand != null) {
        _selectedBrand = foundBrand;
        _brandModels = results.where((m) => m.brand == foundBrand).toList();
      } else if (results.isNotEmpty) {
        _selectedBrand = results.first.brand;
        _brandModels = results.where((m) => m.brand == _selectedBrand).toList();
      } else {
        _selectedBrand = null;
        _brandModels = [];
      }
    });
  }

  void _toggleBrandExpansion(String brand) {
    setState(() {
      if (_expandedBrand == brand) {
        _expandedBrand = null;
      } else {
        _expandedBrand = brand;
        _brandModels =
            MotorcycleDataService.getMotorcyclesByBrand(brand).toList();
      }
      _selectedBrand = null;
      _selectedMotorcycle = null;
    });
  }

  void _selectMotorcycle(MotorcycleModel motorcycle) {
    setState(() {
      _selectedMotorcycle = motorcycle;
      _resolvedModelImagePath = null;
    });
    _resolveModelImagePath(motorcycle);
  }

  Future<void> _resolveModelImagePath(MotorcycleModel motorcycle) async {
    final brandFolder = motorcycle.brand
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();
    final modelFile =
        motorcycle.model.replaceAll(' ', '-').replaceAll('/', '-');

    final candidates = <String>[
      'assets/marca/$brandFolder/$modelFile.png',
      'assets/marca/$brandFolder/${modelFile.toLowerCase()}.png',
      'assets/marca/$brandFolder/${modelFile.toUpperCase()}.png',
      'assets/marca/$modelFile.png',
      'assets/marca/${modelFile.toLowerCase()}.png',
      'assets/marca/${modelFile.toUpperCase()}.png',
    ];

    for (final path in candidates) {
      try {
        // ignore: avoid_print
        print('[MotorcycleImage] trying asset: $path');
        await rootBundle.load(path);
        // ignore: avoid_print
        print('[MotorcycleImage] found asset: $path');
        if (!mounted) return;
        setState(() {
          _resolvedModelImagePath = path;
        });
        return;
      } catch (e) {
        // ignore: avoid_print
        print('[MotorcycleImage] not found: $path -> $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _resolvedModelImagePath = 'assets/images/moto-black.png';
      // ignore: avoid_print
      print('[MotorcycleImage] fallback to default image');
    });
  }

  void _handleContinue() {
    if (_selectedMotorcycle != null) {
      widget.onComplete(
        motorcycle: _selectedMotorcycle!,
        resolvedImagePath: _resolvedModelImagePath,
        brand: _selectedMotorcycle!.brand,
        model: _selectedMotorcycle!.model,
        plate: 'ABC-1234',
        currentKm: 12450,
        oilType: '10W-40 Sintético',
        frontTirePressure: 2.5,
        rearTirePressure: 2.8,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Banner/Carousel no topo (sempre visível)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                ),
                child: Image.asset(
                  'assets/marca/banner-header.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.racingOrange.withOpacity(0.1),
                    );
                  },
                ),
              ),

              // Campo de busca
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Buscar por modelo ou marca',
                    hintStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black26),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black26),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.racingOrange,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

              // Conteúdo principal
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Grid de logos das marcas (quando não há busca)
                      if (!_isSearching && _selectedMotorcycle == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 16),
                                child: Text(
                                  'Escolha sua marca',
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: _allBrands.length,
                                itemBuilder: (context, index) {
                                  final brand = _allBrands[index];
                                  final isExpanded = _expandedBrand == brand;
                                  final motorcyclesInBrand =
                                      MotorcycleDataService
                                          .getMotorcyclesByBrand(brand);

                                  return GestureDetector(
                                    onTap: () => _toggleBrandExpansion(brand),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isExpanded
                                            ? AppColors.racingOrange
                                                .withOpacity(0.1)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isExpanded
                                              ? AppColors.racingOrange
                                              : Colors.black12,
                                          width: isExpanded ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Image.asset(
                                              motorcyclesInBrand.isNotEmpty
                                                  ? motorcyclesInBrand
                                                      .first.brandImagePath
                                                  : 'assets/images/moto-black.png',
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Text(
                                                  brand,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black54,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                );
                                              },
                                            ),
                                          ),
                                          if (isExpanded)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: Icon(
                                                Icons.expand_less,
                                                color: AppColors.racingOrange,
                                                size: 16,
                                              ),
                                            )
                                          else
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: Icon(
                                                Icons.expand_more,
                                                color: Colors.black54,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      // Acordeão: modelos da marca selecionada
                      if (_expandedBrand != null &&
                          _brandModels.isNotEmpty &&
                          _selectedMotorcycle == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Modelos',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              ..._brandModels.map((moto) {
                                return InkWell(
                                  onTap: () => _selectMotorcycle(moto),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 14),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            moto.model,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                      // Lista de modelos da busca (quando há busca)
                      if (_isSearching &&
                          _brandModels.isNotEmpty &&
                          _selectedMotorcycle == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedBrand != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Image.asset(
                                    _brandModels.first.brandImagePath,
                                    height: 60,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox(height: 60);
                                    },
                                  ),
                                ),
                              ..._brandModels.map((moto) {
                                return InkWell(
                                  onTap: () => _selectMotorcycle(moto),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            moto.model,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                      // Layout com logo, nome do modelo e imagem (quando selecionada)
                      if (_selectedMotorcycle != null) ...[
                        const SizedBox(height: 24),

                        // Logo da marca (no topo, centralizado)
                        Center(
                          child: Image.asset(
                            _selectedMotorcycle!.brandImagePath,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(height: 60);
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Nome do modelo (em vermelho)
                        Center(
                          child: Text(
                            _selectedMotorcycle!.model.toUpperCase(),
                            style: GoogleFonts.lato(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.racingOrange,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        // Caminho resolvido (debug)
                        if (_resolvedModelImagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _resolvedModelImagePath!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ),

                        // Container com fundo cinza escuro e imagem da moto
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Container cinza (menor que a imagem, 10px mais para baixo)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                height: 180,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Indicadores de cor
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Círculo vermelho (selecionado)
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.racingOrange,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Círculo preto
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Círculo branco
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Colors.black12,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),

                            // Imagem da moto (largura total da tela, sobrepondo o container)
                            SizedBox(
                              width: double.infinity,
                              child: Image.asset(
                                _resolvedModelImagePath ??
                                    'assets/images/moto-black.png',
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Especificações detalhadas
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSpecRow('Displacement',
                                  _selectedMotorcycle!.displacement),
                              const SizedBox(height: 14),
                              _buildSpecRow('Horse Power',
                                  _getHorsePower(_selectedMotorcycle!)),
                              const SizedBox(height: 14),
                              _buildSpecRow(
                                  'Torque', _getTorque(_selectedMotorcycle!)),
                              const SizedBox(height: 14),
                              _buildSpecRow('Dry Weight',
                                  _getDryWeight(_selectedMotorcycle!)),
                              const SizedBox(height: 14),
                              _buildSpecRow('Seat Height',
                                  _getSeatHeight(_selectedMotorcycle!)),
                              const SizedBox(height: 14),
                              _buildSpecRow('Safety', _selectedMotorcycle!.abs),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Botão CONTINUAR
              if (_selectedMotorcycle != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.racingOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('CONTINUAR'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.65),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares para obter especificações detalhadas (mockados por enquanto)
  String _getHorsePower(MotorcycleModel moto) {
    // Valores mockados baseados na cilindrada
    final cc = int.tryParse(moto.displacement.replaceAll(' cc', '')) ?? 0;
    if (cc >= 800) return '73 hp (54 kW)';
    if (cc >= 500) return '47 hp (35 kW)';
    if (cc >= 300) return '27 hp (20 kW)';
    if (cc >= 150) return '14 hp (10 kW)';
    return '9 hp (7 kW)';
  }

  String _getTorque(MotorcycleModel moto) {
    final cc = int.tryParse(moto.displacement.replaceAll(' cc', '')) ?? 0;
    if (cc >= 800) return '67 Nm (49.0 lb-ft)';
    if (cc >= 500) return '43 Nm (32.0 lb-ft)';
    if (cc >= 300) return '27 Nm (20.0 lb-ft)';
    if (cc >= 150) return '14 Nm (10.0 lb-ft)';
    return '9 Nm (7.0 lb-ft)';
  }

  String _getDryWeight(MotorcycleModel moto) {
    final cc = int.tryParse(moto.displacement.replaceAll(' cc', '')) ?? 0;
    if (cc >= 800) return '175 Kg (386 lb)';
    if (cc >= 500) return '195 Kg (430 lb)';
    if (cc >= 300) return '170 Kg (375 lb)';
    if (cc >= 150) return '130 Kg (287 lb)';
    return '110 Kg (243 lb)';
  }

  String _getSeatHeight(MotorcycleModel moto) {
    final cc = int.tryParse(moto.displacement.replaceAll(' cc', '')) ?? 0;
    if (cc >= 800) return '805 mm (31.69 in)';
    if (cc >= 500) return '790 mm (31.10 in)';
    if (cc >= 300) return '780 mm (30.71 in)';
    if (cc >= 150) return '780 mm (30.71 in)';
    return '750 mm (29.53 in)';
  }
}
