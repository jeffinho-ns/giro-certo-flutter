import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/colors.dart';
import '../../models/motorcycle_model.dart';
import '../../models/garage_setup_result.dart';
import '../../models/vehicle_type.dart';
import '../../services/motorcycle_data_service.dart';

class GarageSetupScreen extends StatefulWidget {
  final void Function(GarageSetupResult result) onComplete;

  const GarageSetupScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<GarageSetupScreen> createState() => _GarageSetupScreenState();
}

class _GarageSetupScreenState extends State<GarageSetupScreen> {
  final _searchController = TextEditingController();
  final _bicycleBrandController = TextEditingController();
  final _bicycleAroController = TextEditingController();
  final _bicycleCorController = TextEditingController();
  final _bicycleObsController = TextEditingController();

  AppVehicleType _vehicleType = AppVehicleType.motorcycle;
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
    _bicycleBrandController.dispose();
    _bicycleAroController.dispose();
    _bicycleCorController.dispose();
    _bicycleObsController.dispose();
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

  void _handleContinueMotorcycle() {
    if (_selectedMotorcycle == null) return;
    widget.onComplete(
      GarageSetupResult(
        mode: AppVehicleType.motorcycle,
        motorcycle: _selectedMotorcycle!,
        resolvedImagePath: _resolvedModelImagePath,
        brand: _selectedMotorcycle!.brand,
        model: _selectedMotorcycle!.model,
        plate: 'ABC-1234',
        currentKm: 12450,
        oilType: '10W-40 Sintético',
        frontTirePressure: 2.5,
        rearTirePressure: 2.8,
      ),
    );
  }

  void _setVehicleType(AppVehicleType t) {
    if (t == _vehicleType) return;
    setState(() {
      _vehicleType = t;
      _searchController.clear();
      _isSearching = false;
      _selectedMotorcycle = null;
      _resolvedModelImagePath = null;
      _selectedBrand = null;
      _brandModels = [];
      _expandedBrand = null;
    });
  }

  void _handleContinueBicycle() {
    final brand = _bicycleBrandController.text.trim();
    final aro = _bicycleAroController.text.trim();
    final cor = _bicycleCorController.text.trim();
    final obs = _bicycleObsController.text.trim();
    if (brand.isEmpty || aro.isEmpty || cor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha marca, aro e cor para continuar.'),
        ),
      );
      return;
    }
    widget.onComplete(
      GarageSetupResult(
        mode: AppVehicleType.bicycle,
        motorcycle: null,
        resolvedImagePath: null,
        brand: brand,
        model: 'Aro $aro',
        plate: '',
        currentKm: 0,
        oilType: '—',
        frontTirePressure: 0,
        rearTirePressure: 0,
        bicycleAro: aro,
        bicycleCor: cor,
        bicycleObservacao: obs.isEmpty ? null : obs,
      ),
    );
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

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _buildModeToggle(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _vehicleType == AppVehicleType.motorcycle
                        ? 'Escolha sua marca'
                        : 'Sua bicicleta',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              if (_vehicleType == AppVehicleType.motorcycle)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Buscar por modelo ou marca',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: const Color(0xFFF4F4F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
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
                child: _vehicleType == AppVehicleType.bicycle
                    ? _buildBicycleForm()
                    : SingleChildScrollView(
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
              if (_vehicleType == AppVehicleType.motorcycle &&
                  _selectedMotorcycle != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleContinueMotorcycle,
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
              if (_vehicleType == AppVehicleType.bicycle)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleContinueBicycle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.racingOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeSegment(
              label: 'Moto',
              icon: LucideIcons.rocket,
              selected: _vehicleType == AppVehicleType.motorcycle,
              onTap: () => _setVehicleType(AppVehicleType.motorcycle),
            ),
          ),
          Expanded(
            child: _modeSegment(
              label: 'Bicicleta',
              icon: LucideIcons.bike,
              selected: _vehicleType == AppVehicleType.bicycle,
              onTap: () => _setVehicleType(AppVehicleType.bicycle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSegment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.racingOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.racingOrange.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBicycleForm() {
    InputDecoration deco(String hint) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.racingOrange, width: 2),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informe os dados básicos. Eles entram na sua garagem após a aprovação do cadastro de entregador.',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _bicycleBrandController,
            decoration: deco('Marca (ex.: Caloi, Oggi)'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bicycleAroController,
            decoration: deco('Aro (ex.: 26, 29, 700C)'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bicycleCorController,
            decoration: deco('Cor'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bicycleObsController,
            minLines: 2,
            maxLines: 4,
            decoration: deco('Observação (opcional)'),
          ),
          const SizedBox(height: 24),
        ],
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
