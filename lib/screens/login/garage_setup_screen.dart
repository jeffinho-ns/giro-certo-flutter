import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../models/motorcycle_model.dart';
import '../../services/motorcycle_data_service.dart';

class GarageSetupScreen extends StatefulWidget {
  final Function({
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
  List<MotorcycleModel> _searchResults = [];
  MotorcycleModel? _selectedMotorcycle;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = MotorcycleDataService.searchMotorcycles(query);
    });
  }

  void _selectMotorcycle(MotorcycleModel motorcycle) {
    setState(() {
      _selectedMotorcycle = motorcycle;
      _isSearching = false;
    });
  }

  void _handleContinue() {
    if (_selectedMotorcycle != null) {
      widget.onComplete(
        brand: _selectedMotorcycle!.brand,
        model: _selectedMotorcycle!.model,
        plate: 'ABC-1234', // Placeholder
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFD2D2D2),
            ],
          ),
        ),
        child: SafeArea(
          child: _selectedMotorcycle == null
              ? _buildSearchView()
              : _buildMotorcycleDetailView(),
        ),
      ),
    );
  }

  Widget _buildSearchView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          
          // Campo de busca
          TextField(
            controller: _searchController,
            onChanged: _performSearch,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Buscar por modelo ou marca',
              hintStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
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
          
          const SizedBox(height: 24),
          
          // Resultados da busca
          if (_isSearching && _searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Nenhuma moto encontrada',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else if (_searchResults.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final moto = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Image.asset(
                      moto.brandImagePath,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.motorcycle);
                      },
                    ),
                    title: Text(
                      '${moto.brand} ${moto.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '${moto.displacement} • ${moto.abs}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    onTap: () => _selectMotorcycle(moto),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMotorcycleDetailView() {
    final moto = _selectedMotorcycle!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner/Logo da marca
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.racingOrange.withOpacity(0.1),
            ),
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    moto.brandImagePath,
                    width: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/marca/banner-header.png',
                        width: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.motorcycle, size: 80);
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _selectedMotorcycle = null;
                        _searchController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Nome do modelo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              moto.model.toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Imagem da moto
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/moto-black.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Especificações
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpecRow('Cilindrada', moto.displacement),
                const SizedBox(height: 16),
                _buildSpecRow('ABS / Outros', moto.abs),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Botão CONTINUAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
