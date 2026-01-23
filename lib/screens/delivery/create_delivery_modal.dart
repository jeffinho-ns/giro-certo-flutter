import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order.dart';
import '../../models/partner.dart';
import '../../services/api_service.dart';
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
  List<Partner> _stores = [];
  bool _isLoadingStores = false;
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
      final baseFee = 5.0 + (distance * 2.0);
      
      // Se urgente e opção marcada, entregador recebe 50% a mais
      // Ex: se baseFee = 6, entregador recebe 9 (6 + 50% de 6)
      final calculatedFee = (_selectedPriority == DeliveryPriority.urgent && _increaseFeeForUrgent)
          ? baseFee * 1.5 // Aumenta 50% para o entregador
          : baseFee;
      
      setState(() {
        _deliveryFee = calculatedFee;
      });
    } else if (_selectedStore != null) {
      // Se tiver loja mas não tiver endereço de entrega, calcular taxa mínima
      setState(() {
        _deliveryFee = 5.0; // Taxa base mínima
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

  String _priorityToString(DeliveryPriority priority) {
    switch (priority) {
      case DeliveryPriority.low:
        return 'low';
      case DeliveryPriority.normal:
        return 'normal';
      case DeliveryPriority.high:
        return 'high';
      case DeliveryPriority.urgent:
        return 'urgent';
    }
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma loja'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar endereço de entrega
    if (_deliveryAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o endereço de entrega'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Se não tiver coordenadas, usar coordenadas simuladas baseadas na loja
    if (_deliveryLatitude == null || _deliveryLongitude == null) {
      if (_selectedStore != null) {
        // Simular coordenadas próximas à loja
        setState(() {
          _deliveryLatitude = _selectedStore!.latitude + 0.01;
          _deliveryLongitude = _selectedStore!.longitude + 0.01;
        });
        _calculateDeliveryFee();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao calcular localização. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Garantir que a taxa foi calculada
    if (_deliveryFee == null) {
      _calculateDeliveryFee();
      if (_deliveryFee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao calcular taxa de entrega'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Validar valor do pedido
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o valor do pedido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final value = double.tryParse(valueText.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valor do pedido inválido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    var loadingDismissed = false;
    void dismissLoading() {
      if (!loadingDismissed && mounted) {
        loadingDismissed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      // Debug: log antes de criar
      print('🚀 Criar pedido: store=${_selectedStore!.id} ${_selectedStore!.name}, '
          'endereço=${_deliveryAddressController.text.trim().length} chars, '
          'valor=$value, taxa=${_deliveryFee}');

      // Criar pedido na API
      await ApiService.createDeliveryOrder(
        storeId: _selectedStore!.id,
        storeName: _selectedStore!.name,
        storeAddress: _selectedStore!.address,
        storeLatitude: _selectedStore!.latitude,
        storeLongitude: _selectedStore!.longitude,
        deliveryAddress: _deliveryAddressController.text.trim(),
        deliveryLatitude: _deliveryLatitude!,
        deliveryLongitude: _deliveryLongitude!,
        recipientName: _recipientNameController.text.trim().isNotEmpty
            ? _recipientNameController.text.trim()
            : null,
        recipientPhone: _recipientPhoneController.text.trim().isNotEmpty
            ? _recipientPhoneController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        value: value,
        deliveryFee: _deliveryFee!,
        priority: _priorityToString(_selectedPriority),
      );

      print('✅ Pedido criado com sucesso');
      dismissLoading();
      if (!mounted) return;

      // Atualizar lista na home antes de fechar
      widget.onOrderCreated();

      // Mostrar sucesso (context ainda válido)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido criado com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Fechar modal (bottom sheet) pelo root navigator
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e, st) {
      print('❌ Erro ao criar pedido: $e');
      print('$st');
      dismissLoading();
      if (!mounted) return;

      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar pedido: $msg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoadingStores = true;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final user = appState.user;
      
      if (user?.partnerId != null) {
        // Buscar a loja do usuário logado usando o endpoint /me
        try {
          final partner = await ApiService.getMyPartner().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Tempo de espera esgotado. Verifique sua conexão.');
            },
          );
          
          setState(() {
            _stores = [partner];
            _selectedStore = partner;
            _isLoadingStores = false;
          });
          
          // Calcular taxa inicial (mesmo sem endereço, mostra taxa mínima)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _calculateDeliveryFee();
            }
          });
        } catch (e) {
          print('Erro ao buscar loja do usuário: $e');
          
          // Se falhar, criar uma loja temporária com dados do usuário
          // para não travar a tela
          final errorMessage = e.toString();
          final is403 = errorMessage.contains('403') || errorMessage.contains('restrito');
          
          if (is403) {
            // Se for erro 403, a API ainda não tem a rota /me implementada
            // Criar loja temporária com dados básicos
            final tempPartner = Partner(
              id: user!.partnerId!,
              name: user.name, // Usar nome do usuário como nome da loja temporariamente
              type: PartnerType.store,
              address: 'Endereço não disponível',
              latitude: -23.5505, // Coordenadas padrão (São Paulo)
              longitude: -46.6333,
              rating: 0.0,
              isTrusted: false,
              specialties: [],
              activePromotions: [],
            );
            
            setState(() {
              _stores = [tempPartner];
              _selectedStore = tempPartner;
              _isLoadingStores = false;
            });
            
            // Calcular taxa inicial
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _calculateDeliveryFee();
              }
            });
            
            // Mostrar aviso ao usuário
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Atenção: Alguns dados da loja podem estar incompletos. Entre em contato com o suporte.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } else {
            // Outro tipo de erro
            setState(() {
              _isLoadingStores = false;
            });
            
            // Mostrar erro ao usuário
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao carregar dados da loja. Tente novamente.'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      } else {
        // Se não for lojista, não deveria estar aqui, mas vamos tratar
        setState(() {
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar lojas: $e');
      setState(() {
        _isLoadingStores = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar dados. Tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                      _isLoadingStores
                          ? const Center(child: CircularProgressIndicator())
                          : _stores.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                  ),
                                  child: Text(
                                    'Carregando loja...',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                )
                              : _stores.length == 1
                                  ? // Se tiver apenas uma loja, mostrar como campo de texto (não editável)
                                  Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.store,
                                            color: AppColors.racingOrange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedStore?.name ?? 'Loja',
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (_selectedStore != null)
                                                  Text(
                                                    _selectedStore!.address,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : // Se tiver múltiplas lojas, mostrar dropdown
                                  DropdownButtonFormField<Partner>(
                                      value: _selectedStore != null && _stores.contains(_selectedStore) 
                                          ? _selectedStore 
                                          : (_stores.isNotEmpty ? _stores.first : null),
                                      decoration: InputDecoration(
                                        hintText: 'Selecione a loja',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      items: _stores.map((store) {
                                        return DropdownMenuItem<Partner>(
                                          value: store,
                                          child: Text(store.name),
                                        );
                                      }).toList(),
                                      onChanged: (store) {
                                        setState(() {
                                          _selectedStore = store;
                                          if (store != null) {
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
                      // Mostrar endereço da loja selecionada se tiver múltiplos endereços
                      if (_selectedStore != null && _stores.length > 1) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 16,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedStore!.address,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
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
                          // Simular geocodificação - usar coordenadas da loja como base
                          if (value.length > 10 && _selectedStore != null) {
                            setState(() {
                              // Simular coordenadas próximas à loja
                              _deliveryLatitude = _selectedStore!.latitude + 0.01;
                              _deliveryLongitude = _selectedStore!.longitude + 0.01;
                            });
                            // Calcular taxa após atualizar coordenadas
                            _calculateDeliveryFee();
                          } else if (value.isEmpty) {
                            // Se limpar o endereço, limpar coordenadas mas manter taxa mínima
                            setState(() {
                              _deliveryLatitude = null;
                              _deliveryLongitude = null;
                            });
                            _calculateDeliveryFee();
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
                                    // Recalcular taxa quando mudar o switch
                                    if (_selectedStore != null && 
                                        _deliveryLatitude != null && 
                                        _deliveryLongitude != null) {
                                      _calculateDeliveryFee();
                                    }
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
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
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
              ),
            ],
          ),
        );
      },
    );
  }
}

