import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/delivery_order.dart';
import '../../models/rider_stats.dart';
import '../../services/api_service.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/rider_dashboard.dart';
import 'delivery_order_card.dart';
import 'create_delivery_modal.dart';
import 'delivery_detail_modal.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  final MapController _mapController = MapController();
  
  // Localização do usuário (TODO: obter via GPS)
  double _userLatitude = -23.5505;
  double _userLongitude = -46.6333;
  
  bool _isLoading = false;
  String? _loadError;
  List<DeliveryOrder> _orders = [];
  List<DeliveryOrder> _myOrders = []; // Corridas aceitas pelo usuário
  List<DeliveryOrder> _completedOrders = []; // Corridas concluídas
  RiderStats? _riderStats;

  // Determina se é motociclista ou lojista baseado no usuário logado
  bool get _isRiderMode {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    return appState.user?.isRider ?? true; // Default para motociclista
  }

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadOrders();
  }

  void _initializeTabController() {
    _tabController?.dispose();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isRider = appState.user?.isRider ?? true;
    
    _tabController = TabController(
      length: isRider ? 3 : 2, 
      vsync: this,
      initialIndex: 0,
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final user = appState.user;
      
      if (user == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'Sessao expirada. Faca login novamente.';
        });
        return;
      }

      // Integrar com API real
      if (_isRiderMode) {
        // Motociclista: buscar pedidos disponíveis e seus próprios pedidos
        final allOrders = await ApiService.getDeliveryOrders();
        final myOrders = await ApiService.getDeliveryOrders(riderId: user.id);
        
        setState(() {
          _orders = allOrders.where((o) => o.status == DeliveryStatus.pending).toList();
          _myOrders = myOrders.where((o) => 
            o.status == DeliveryStatus.accepted || 
            o.status == DeliveryStatus.arrivedAtStore ||
            o.status == DeliveryStatus.inTransit ||
            o.status == DeliveryStatus.inProgress
          ).toList();
          _completedOrders = myOrders.where((o) => o.status == DeliveryStatus.completed).toList();
          _riderStats = RiderStats.fromOrders(_completedOrders);
          _isLoading = false;
        });
      } else {
        // Lojista: buscar apenas seus próprios pedidos
        if (user.partnerId != null) {
          final myOrders = await ApiService.getDeliveryOrders(storeId: user.partnerId);
          
          setState(() {
            _orders = myOrders.where((o) => o.status == DeliveryStatus.pending).toList();
            _myOrders = myOrders.where((o) => 
              o.status == DeliveryStatus.accepted || 
              o.status == DeliveryStatus.arrivedAtStore ||
              o.status == DeliveryStatus.inTransit ||
              o.status == DeliveryStatus.inProgress
            ).toList();
            _completedOrders = myOrders.where((o) => o.status == DeliveryStatus.completed).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _orders = [];
            _myOrders = [];
            _completedOrders = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      final message = 'Erro ao carregar pedidos: $e';
      if (mounted) {
        setState(() {
          _loadError = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptOrder(DeliveryOrder order) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null) return;
    
    try {
      final updatedOrder = await ApiService.acceptOrder(
        order.id,
        riderId: user.id,
        riderName: user.name,
      );
      
      setState(() {
        _orders.removeWhere((o) => o.id == order.id);
        _myOrders.removeWhere((o) => o.id == updatedOrder.id);
        _myOrders.add(updatedOrder);
        
        // Atualizar estatísticas
        _updateStats();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Corrida aceita! Ganhos estimados: R\$ ${order.deliveryFee.toStringAsFixed(2)}'),
            backgroundColor: AppColors.neonGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aceitar corrida: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _updateStats() {
    if (_isRiderMode) {
      final allOrders = [..._orders, ..._completedOrders];
      _riderStats = RiderStats.fromOrders(allOrders);
    }
  }

  Future<void> _completeOrder(DeliveryOrder order) async {
    try {
      final updatedOrder = await ApiService.completeOrder(order.id);
      
      setState(() {
        _orders.removeWhere((o) => o.id == order.id);
        _myOrders.removeWhere((o) => o.id == order.id);
        _completedOrders.insert(0, updatedOrder);
        
        // Atualizar estatísticas
        _updateStats();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Corrida concluída! Ganhos: R\$ ${order.deliveryFee.toStringAsFixed(2)}'),
            backgroundColor: AppColors.neonGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao concluir corrida: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _advanceDeliveryStage(DeliveryOrder order) async {
    try {
      DeliveryOrder updatedOrder;
      String successMessage;
      if (order.status == DeliveryStatus.accepted) {
        updatedOrder = await ApiService.markArrivedAtStore(order.id);
        successMessage = 'Chegada na loja confirmada.';
      } else if (order.status == DeliveryStatus.arrivedAtStore) {
        updatedOrder = await ApiService.startTransit(order.id);
        successMessage = 'Entrega iniciada. Siga para o cliente.';
      } else if (order.status == DeliveryStatus.inTransit || order.status == DeliveryStatus.inProgress) {
        await _completeOrder(order);
        return;
      } else {
        return;
      }

      if (!mounted) return;
      setState(() {
        final index = _myOrders.indexWhere((o) => o.id == updatedOrder.id);
        if (index != -1) {
          _myOrders[index] = updatedOrder;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.neonGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar etapa da corrida: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final pendingOrders = _orders.where((o) => o.status == DeliveryStatus.pending).toList();
    
    return Scaffold(
      body: Column(
        children: [
          ModernHeader(
            title: _isRiderMode ? 'Corridas' : 'Meus Pedidos',
            showBackButton: false,
          ),
          
          // Tabs - Verificar que TabController existe e tem o tamanho correto
          if (_tabController != null && _tabController!.length == (_isRiderMode ? 3 : 2))
            TabBar(
              controller: _tabController!,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              tabs: _isRiderMode 
                ? [
                    Tab(
                      icon: Icon(LucideIcons.map),
                      text: 'Mapa',
                    ),
                    Tab(
                      icon: Icon(LucideIcons.list),
                      text: 'Disponíveis',
                    ),
                    Tab(
                      icon: Icon(LucideIcons.package),
                      text: 'Minhas Corridas',
                    ),
                  ]
                : [
                    Tab(
                      icon: Icon(LucideIcons.map),
                      text: 'Áreas Quentes',
                    ),
                    Tab(
                      icon: Icon(LucideIcons.list),
                      text: 'Meus Pedidos',
                    ),
                  ],
            )
          else
            SizedBox(height: 48), // Placeholder enquanto TabController não está pronto
          
          // Conteúdo - Verificar que TabController existe e tem o tamanho correto
          Expanded(
            child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ),
                )
              : _loadError != null
                ? _buildLoadErrorState(theme, primaryColor)
              : _tabController != null && _tabController!.length == (_isRiderMode ? 3 : 2)
                ? Stack(
                    children: [
                      TabBarView(
                        controller: _tabController!,
                        children: _isRiderMode
                          ? [
                              _buildMapView(theme, pendingOrders, primaryColor),
                              _buildRiderOrdersList(theme, pendingOrders, primaryColor),
                              _buildMyDeliveriesView(theme),
                            ]
                          : [
                              _buildMapView(theme, pendingOrders, primaryColor),
                              _buildStoreOrdersList(theme),
                            ],
                      ),
                      // Botão flutuante de criar pedido (apenas para lojista)
                      if (!_isRiderMode)
                        Positioned(
                          bottom: 90, // Acima do menu inferior
                          right: 16,
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => CreateDeliveryModal(
                                  userLat: _userLatitude,
                                  userLng: _userLongitude,
                                  onOrderCreated: () {
                                    _loadOrders();
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                            backgroundColor: primaryColor,
                            icon: Icon(LucideIcons.plus),
                            label: Text('Novo Pedido'),
                            elevation: 8,
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadErrorState(ThemeData theme, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: 56,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Nao foi possivel carregar os pedidos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Falha de conexao.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(ThemeData theme, List<DeliveryOrder> orders, Color primaryColor) {
    final userLocation = LatLng(_userLatitude, _userLongitude);
    // TODO: Implementar hot zones via API quando disponível
    final hotZones = <Map<String, dynamic>>[];
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLocation,
            initialZoom: 13.0,
            minZoom: 10.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.girocerto.app',
              maxZoom: 19,
            ),
            
            MarkerLayer(
              markers: [
                // Localização do usuário
                Marker(
                  point: userLocation,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
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
                      size: 20,
                    ),
                  ),
                ),
                
                // Zonas quentes (mapa de calor)
                ...hotZones.map((zone) {
                  final zonePoint = LatLng(zone['latitude'] as double, zone['longitude'] as double);
                  final orderCount = zone['orderCount'] as int;
                  final size = 30.0 + (orderCount * 5.0); // Tamanho baseado na quantidade
                  
                  return Marker(
                    point: zonePoint,
                    width: size,
                    height: size,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$orderCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                // Marcadores de pedidos pendentes
                ...orders.map((order) {
                  final storePoint = LatLng(order.storeLatitude, order.storeLongitude);
                  final deliveryPoint = LatLng(order.deliveryLatitude, order.deliveryLongitude);
                  
                  return [
                    // Loja - apenas ícone para evitar overflow
                    Marker(
                      point: storePoint,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showOrderDetail(order),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.store,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    // Entrega
                    Marker(
                      point: deliveryPoint,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showOrderDetail(order),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonGreen.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.mapPin,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ];
                }).expand((markers) => markers).toList(),
              ],
            ),
          ],
        ),
        // Botão de voltar para home (mesma posição da Marketplace)
        Positioned(
          top: 16,
          left: 16,
          child: SafeArea(
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  final navProvider = Provider.of<NavigationProvider>(context, listen: false);
                  Navigator.of(context).pop();
                  navProvider.navigateTo(2);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.home,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderOrdersList(ThemeData theme, List<DeliveryOrder> orders, Color primaryColor) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.package,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma corrida disponível',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Ordenar por prioridade e distância
    final sortedOrders = List<DeliveryOrder>.from(orders);
    sortedOrders.sort((a, b) {
      final priorityOrder = {
        DeliveryPriority.urgent: 0,
        DeliveryPriority.high: 1,
        DeliveryPriority.normal: 2,
        DeliveryPriority.low: 3,
      };
      final priorityDiff = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      if (priorityDiff != 0) return priorityDiff;
      return (a.distance ?? 0).compareTo(b.distance ?? 0);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedOrders.length,
      itemBuilder: (context, index) {
        final order = sortedOrders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DeliveryOrderCard(
            order: order,
            userLat: _userLatitude,
            userLng: _userLongitude,
            onTap: () => _showOrderDetail(order),
            onAccept: () => _acceptOrder(order),
            showAcceptButton: true,
          ),
        );
      },
    );
  }

  Widget _buildStoreOrdersList(ThemeData theme) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final partnerId = appState.user?.partnerId;
    
    // Filtrar apenas pedidos do parceiro logado
    final myStoreOrders = partnerId != null
        ? _orders.where((o) => o.storeId == partnerId).toList()
        : _orders; // Fallback: mostrar todos se não houver partnerId

    if (myStoreOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shoppingBag,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum pedido criado ainda',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + para criar um novo pedido',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myStoreOrders.length,
      itemBuilder: (context, index) {
        final order = myStoreOrders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DeliveryOrderCard(
            order: order,
            userLat: _userLatitude,
            userLng: _userLongitude,
            onTap: () => _showOrderDetail(order),
            showAcceptButton: false,
          ),
        );
      },
    );
  }

  Widget _buildMyDeliveriesView(ThemeData theme) {
    if (_riderStats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.package,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Carregando suas estatísticas...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Se não há corridas ativas nem histórico, mostrar mensagem
    if (_myOrders.isEmpty && _completedOrders.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Dashboard de ganhos
            RiderDashboard(stats: _riderStats!),
            const SizedBox(height: 40),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.package,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma corrida ainda',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aceite corridas para começar a ganhar!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    // Usar ListView customizado para evitar overflow
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Dashboard de ganhos
        RiderDashboard(stats: _riderStats!),
        
        // Corridas ativas
        if (_myOrders.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Corridas Ativas (${_myOrders.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ..._myOrders.map((order) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                DeliveryOrderCard(
                  order: order,
                  userLat: _userLatitude,
                  userLng: _userLongitude,
                  onTap: () => _showOrderDetail(order),
                  showAcceptButton: false,
                ),
                const SizedBox(height: 8),
                _buildRiderStageAction(theme, order),
              ],
            ),
          )),
          const SizedBox(height: 16),
        ],
        
        // Histórico de corridas concluídas
        if (_completedOrders.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histórico de Corridas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_completedOrders.length} concluídas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ...(_completedOrders.length > 10 
            ? _completedOrders.take(10) 
            : _completedOrders).map((order) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.check,
                      color: AppColors.neonGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.storeName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Concluída ${_formatDate(order.completedAt ?? order.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'R\$ ${order.deliveryFee.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildRiderStageAction(ThemeData theme, DeliveryOrder order) {
    String? label;
    Color backgroundColor = theme.colorScheme.primary;
    if (order.status == DeliveryStatus.accepted) {
      label = 'Confirmar chegada na loja';
      backgroundColor = AppColors.racingOrange;
    } else if (order.status == DeliveryStatus.arrivedAtStore) {
      label = 'Coletar e iniciar entrega';
      backgroundColor = Colors.deepOrange;
    } else if (order.status == DeliveryStatus.inTransit || order.status == DeliveryStatus.inProgress) {
      label = 'Finalizar entrega';
      backgroundColor = AppColors.neonGreen;
    }

    if (label == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _advanceDeliveryStage(order),
        icon: const Icon(LucideIcons.navigation, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return 'hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateDay == yesterday) {
      return 'ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showOrderDetail(DeliveryOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryDetailModal(
        order: order,
        userLat: _userLatitude,
        userLng: _userLongitude,
        onAccept: () {
          Navigator.pop(context);
          _acceptOrder(order);
        },
        onComplete: () {
          Navigator.pop(context);
          _completeOrder(order);
        },
        isRider: _isRiderMode,
      ),
    );
  }
}

