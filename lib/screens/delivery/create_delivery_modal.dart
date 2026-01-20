import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/delivery_order.dart';
import '../../models/partner.dart';
import '../../services/mock_data_service.dart';
import '../../utils/colors.dart';

class CreateDeliveryModal extends StatefulWidget {
  final double userLat;
  final double userLng;
  final VoidCallback onOrderCreated;

  const CreateDeliveryModal({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.onOrderCreated,
  });

  @override
  State<CreateDeliveryModal> createState() => _CreateDeliveryModalState();
}

class _CreateDeliveryModalState extends State<CreateDeliveryModal> {
  final _formKey = GlobalKey<FormState>();
  final _deliveryAddressController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _valueController = TextEditingController();
  
  Partner? _selectedStore;
  DeliveryPriority _selectedPriority = DeliveryPriority.normal;
  double? _deliveryLatitude;
  double? _deliveryLongitude;
  double? _deliveryFee;

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _notesController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _calculateDeliveryFee() {
    if (_selectedStore != null && _deliveryLatitude != null && _deliveryLongitude != null) {
      // Simulação: R$ 5 base + R$ 2 por km
      final distance = _calculateDistance(
        _selectedStore!.latitude,
        _selectedStore!.longitude,
        _deliveryLatitude!,
        _deliveryLongitude!,
      );
      setState(() {
        _deliveryFee = 5.0 + (distance * 2.0);
      });
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  void _createOrder() {
    if (_formKey.currentState!.validate() && _selectedStore != null && _deliveryFee != null) {
      // Aqui você criaria o pedido na API
      // Por enquanto, apenas chamamos o callback
      widget.onOrderCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stores = MockDataService.getMockPartners()
        .where((p) => p.type == PartnerType.store)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.racingOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.plus,
                              color: AppColors.racingOrange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Novo Pedido de Entrega',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Seleção da loja
                      Text(
                        'Loja',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Partner>(
                        value: _selectedStore,
                        decoration: InputDecoration(
                          hintText: 'Selecione a loja',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: stores.map((store) {
                          return DropdownMenuItem(
                            value: store,
                            child: Text(store.name),
                          );
                        }).toList(),
                        onChanged: (store) {
                          setState(() {
                            _selectedStore = store;
                            _calculateDeliveryFee();
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecione uma loja';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Endereço de entrega
                      Text(
                        'Endereço de Entrega',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _deliveryAddressController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Rua Exemplo, 123 - Bairro, Cidade',
                          prefixIcon: Icon(LucideIcons.mapPin),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe o endereço de entrega';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Simular geocodificação
                          if (value.length > 10) {
                            setState(() {
                              _deliveryLatitude = widget.userLat + 0.01;
                              _deliveryLongitude = widget.userLng + 0.01;
                              _calculateDeliveryFee();
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Nome do destinatário
                      TextFormField(
                        controller: _recipientNameController,
                        decoration: InputDecoration(
                          labelText: 'Nome do Destinatário',
                          prefixIcon: Icon(LucideIcons.user),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe o nome do destinatário';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Telefone do destinatário
                      TextFormField(
                        controller: _recipientPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Telefone do Destinatário',
                          prefixIcon: Icon(LucideIcons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe o telefone';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Valor do pedido
                      TextFormField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          labelText: 'Valor do Pedido (R\$)',
                          prefixIcon: Icon(LucideIcons.dollarSign),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe o valor do pedido';
                          }
                          final numValue = double.tryParse(value);
                          if (numValue == null || numValue <= 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Prioridade
                      Text(
                        'Prioridade',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<DeliveryPriority>(
                        segments: [
                          ButtonSegment(
                            value: DeliveryPriority.low,
                            label: Text('Baixa'),
                          ),
                          ButtonSegment(
                            value: DeliveryPriority.normal,
                            label: Text('Normal'),
                          ),
                          ButtonSegment(
                            value: DeliveryPriority.high,
                            label: Text('Alta'),
                          ),
                          ButtonSegment(
                            value: DeliveryPriority.urgent,
                            label: Text('Urgente'),
                          ),
                        ],
                        selected: {_selectedPriority},
                        onSelectionChanged: (Set<DeliveryPriority> newSelection) {
                          setState(() {
                            _selectedPriority = newSelection.first;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Observações
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Observações (opcional)',
                          prefixIcon: Icon(LucideIcons.messageSquare),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Taxa de entrega calculada
                      if (_deliveryFee != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.neonGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Taxa de Entrega',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'R\$ ${_deliveryFee!.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.neonGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Botão criar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.racingOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.check),
                              const SizedBox(width: 8),
                              Text(
                                'Criar Pedido',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

