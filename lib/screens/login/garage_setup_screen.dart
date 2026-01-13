import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class GarageSetupScreen extends StatefulWidget {
  final Function({
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
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _currentKmController = TextEditingController(text: '12450');
  final _oilTypeController = TextEditingController(text: '10W-40 Sintético');
  final _frontTireController = TextEditingController(text: '2.5');
  final _rearTireController = TextEditingController(text: '2.8');

  @override
  void dispose() {
    _plateController.dispose();
    _currentKmController.dispose();
    _oilTypeController.dispose();
    _frontTireController.dispose();
    _rearTireController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    if (_formKey.currentState!.validate()) {
      widget.onComplete(
        plate: _plateController.text,
        currentKm: int.parse(_currentKmController.text),
        oilType: _oilTypeController.text,
        frontTirePressure: double.parse(_frontTireController.text),
        rearTirePressure: double.parse(_rearTireController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGrafite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configurar Garagem'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Dados Técnicos',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure os dados da sua moto para começar o monitoramento',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _plateController,
                  decoration: const InputDecoration(
                    labelText: 'Placa',
                    hintText: 'ABC-1234',
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a placa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _currentKmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quilometragem Atual (km)',
                    prefixIcon: Icon(Icons.speed),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a quilometragem';
                    }
                    final km = int.tryParse(value);
                    if (km == null || km < 0) {
                      return 'Quilometragem inválida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _oilTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Óleo',
                    hintText: 'Ex: 10W-40 Sintético',
                    prefixIcon: Icon(Icons.water_drop),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o tipo de óleo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _frontTireController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pressão Pneu Dianteiro (bar)',
                    prefixIcon: Icon(Icons.circle),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a pressão';
                    }
                    final pressure = double.tryParse(value);
                    if (pressure == null || pressure <= 0) {
                      return 'Pressão inválida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _rearTireController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pressão Pneu Traseiro (bar)',
                    prefixIcon: Icon(Icons.circle),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a pressão';
                    }
                    final pressure = double.tryParse(value);
                    if (pressure == null || pressure <= 0) {
                      return 'Pressão inválida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _handleComplete,
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
