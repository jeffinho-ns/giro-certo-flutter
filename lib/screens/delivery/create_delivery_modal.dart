import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order.dart';
import '../../models/partner.dart';
import '../../services/mock_data_service.dart';
import '../../providers/app_state_provider.dart';
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
  bool _increaseFeeForUrgent = false;

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
      var baseFee = 5.0 + (distance * 2.0);
      
      // Aumentar taxa se urgente e opção marcada
      if (_selectedPriority == DeliveryPriority.urgent && _increaseFeeForUrgent) {
        baseFee *= 1.5; // Aumenta 50%
      }
      
      setState(() {
        _deliveryFee = baseFee;
      });
    }
  }
  
  Color _getPriorityColor(DeliveryPriority priority) {
    switch (priority) {
      case DeliveryPriority.urgent:
        return Colors.red;
      case DeliveryPriority.high:
        return AppColors.racingOrange;
      case DeliveryPriority.normal:
        return Colors.blue;
      case DeliveryPriority.low:
        return Colors.grey;
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
  void initState() {
    super.initState();
    // Não definir loja inicial aqui - será feito no build
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stores = MockDataService.getMockPartners()
        .where((p) => p.type == PartnerType.store)
        .toList();
    
    // Selecionar primeira loja por padrão se ainda não selecionada
    if (_selectedStore == null && stores.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedStore = stores.first;
          });
        }
      });
    }
    
    // Verificar se a loja selecionada ainda existe na lista
    if (_selectedStore != null && !stores.contains(_selectedStore)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedStore = stores.isNotEmpty ? stores.first : null;
          });
        }
      });
    }
    
    // Pré-preencher nome do destinatário se ainda não preenchido
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final user = appState.user;
      
      if (user != null && _recipientNameController.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _recipientNameController.text = user.name;
          }
        });
      }
    } catch (e) {
      // Ignorar se não conseguir acessar o Provider
    }

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
                        value: _selectedStore != null && stores.contains(_selectedStore) 
                            ? _selectedStore 
                            : null,
                        decoration: InputDecoration(
                          hintText: 'Selecione a loja',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: stores.map((store) {
                          return DropdownMenuItem<Partner>(
                            value: store,
                            child: Text(store.name),
                          );
                        }).toList(),
                        onChanged: (store) {
                          setState(() {
                            _selectedStore = store;
                            if (store != null) {
                              // Atualizar endereço da loja quando selecionar
                              _deliveryAddressController.text = store.address;
                              _deliveryLatitude = store.latitude;
                              _deliveryLongitude = store.longitude;
                              _calculateDeliveryFee();
                            }
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Endereço de Entrega',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_selectedStore != null)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _deliveryAddressController.text = _selectedStore!.address;
                                  _deliveryLatitude = _selectedStore!.latitude;
                                  _deliveryLongitude = _selectedStore!.longitude;
                                  _calculateDeliveryFee();
                                });
                              },
                              icon: Icon(LucideIcons.copy, size: 14),
                              label: Text(
                                'Usar endereço da loja',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
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
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: _getPriorityColor(_selectedPriority).withOpacity(0.2),
                          selectedForegroundColor: _getPriorityColor(_selectedPriority),
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                        ),
                        segments: [
                          ButtonSegment(
                            value: DeliveryPriority.low,
                            label: Text('Baixa'),
                            icon: Icon(
                              LucideIcons.circle,
                              size: 12,
                              color: _selectedPriority == DeliveryPriority.low
                                  ? _getPriorityColor(DeliveryPriority.low)
                                  : Colors.grey,
                            ),
                          ),
                          ButtonSegment(
                            value: DeliveryPriority.normal,
                            label: Text('Normal'),
                            icon: Icon(
                              LucideIcons.circle,
                              size: 12,
                              color: _selectedPriority == DeliveryPriority.normal
                                  ? _getPriorityColor(DeliveryPriority.normal)
                                  : Colors.blue,
                            ),
                          ),
                          ButtonSegment(
                            value: DeliveryPriority.high,
                            label: Text('Alta'),
                            icon: Icon(
                              LucideIcons.circle,
                              size: 12,
                              color: _selectedPriority == DeliveryPriority.high
                                  ? _getPriorityColor(DeliveryPriority.high)
                                  : AppColors.racingOrange,
                            ),
                          ),
                          ButtonSegment(
                            value: DeliveryPriority.urgent,
                            label: Text('Urgente'),
                            icon: Icon(
                              LucideIcons.alertCircle,
                              size: 12,
                              color: _selectedPriority == DeliveryPriority.urgent
                                  ? _getPriorityColor(DeliveryPriority.urgent)
                                  : Colors.red,
                            ),
                          ),
                        ],
                        selected: {_selectedPriority},
                        onSelectionChanged: (Set<DeliveryPriority> newSelection) {
                          setState(() {
                            _selectedPriority = newSelection.first;
                            _calculateDeliveryFee();
                          });
                        },
                      ),
                      
                      // Opção para aumentar taxa se urgente
                      if (_selectedPriority == DeliveryPriority.urgent) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.zap,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Aumentar Taxa de Entrega',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Text(
                                      'Aumenta 50% para atrair motociclistas mais rapidamente',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _increaseFeeForUrgent,
                                onChanged: (value) {
                                  setState(() {
                                    _increaseFeeForUrgent = value;
                                    _calculateDeliveryFee();
                                  });
                                },
                                activeColor: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                      
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

