import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/delivery_order.dart';
import '../../services/mock_data_service.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import 'delivery_order_card.dart';
import 'create_delivery_modal.dart';
import 'delivery_detail_modal.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  
  // Localização simulada do usuário (São Paulo centro)
  final double _userLatitude = -23.5505;
  final double _userLongitude = -46.6333;
  
  bool _isRiderMode = true; // true = motociclista, false = lojista
  List<DeliveryOrder> _orders = [];
  List<DeliveryOrder> _myOrders = []; // Corridas aceitas pelo usuário

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    final orders = MockDataService.getMockDeliveryOrders(_userLatitude, _userLongitude);
    setState(() {
      _orders = orders;
      _myOrders = orders.where((o) => o.status == DeliveryStatus.accepted || o.status == DeliveryStatus.inProgress).toList();
    });
  }

  void _acceptOrder(DeliveryOrder order) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userName = appState.user?.name ?? 'Você';
    
    setState(() {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order.copyWith(
          status: DeliveryStatus.accepted,
          riderId: 'current_user',
          riderName: userName,
          acceptedAt: DateTime.now(),
        );
        _myOrders.add(_orders[index]);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Corrida aceita com sucesso!'),
        backgroundColor: AppColors.neonGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _completeOrder(DeliveryOrder order) {
    setState(() {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order.copyWith(
          status: DeliveryStatus.completed,
          completedAt: DateTime.now(),
        );
        _myOrders.removeWhere((o) => o.id == order.id);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Corrida concluída! Ganhos: R\$ ${order.deliveryFee.toStringAsFixed(2)}'),
        backgroundColor: AppColors.neonGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingOrders = _orders.where((o) => o.status == DeliveryStatus.pending).toList();
    
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              ModernHeader(
                title: 'Delivery',
                showBackButton: false,
              ),
              // Botão de voltar para home
              Positioned(
                top: 0,
                left: 16,
                child: SafeArea(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Navegar para a home usando o NavigationProvider
                        final navProvider = Provider.of<NavigationProvider>(context, listen: false);
                        navProvider.navigateToHome();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.home,
                          color: AppColors.racingOrange,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Toggle entre Motociclista e Lojista
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    theme,
                    label: 'Motociclista',
                    icon: LucideIcons.bike,
                    isSelected: _isRiderMode,
                    onTap: () => setState(() => _isRiderMode = true),
                  ),
                ),
                Expanded(
                  child: _buildModeButton(
                    theme,
                    label: 'Lojista',
                    icon: LucideIcons.store,
                    isSelected: !_isRiderMode,
                    onTap: () => setState(() => _isRiderMode = false),
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.racingOrange,
            labelColor: AppColors.racingOrange,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            tabs: [
              Tab(
                icon: Icon(LucideIcons.map),
                text: _isRiderMode ? 'Mapa de Pedidos' : 'Áreas Quentes',
              ),
              Tab(
                icon: Icon(LucideIcons.list),
                text: _isRiderMode ? 'Corridas Disponíveis' : 'Meus Pedidos',
              ),
            ],
          ),
          
          // Conteúdo
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapView(theme, pendingOrders),
                _isRiderMode 
                  ? _buildRiderOrdersList(theme, pendingOrders)
                  : _buildStoreOrdersList(theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isRiderMode ? null : FloatingActionButton.extended(
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
        backgroundColor: AppColors.racingOrange,
        icon: Icon(LucideIcons.plus),
        label: Text('Novo Pedido'),
      ),
    );
  }

  Widget _buildModeButton(ThemeData theme, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.racingOrange.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.racingOrange
                    : theme.iconTheme.color?.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.racingOrange
                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(ThemeData theme, List<DeliveryOrder> orders) {
    final userLocation = LatLng(_userLatitude, _userLongitude);
    final hotZones = MockDataService.getHotDeliveryZones();
    
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
                        color: AppColors.racingOrange.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.racingOrange,
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
                    // Loja
                    Marker(
                      point: storePoint,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showOrderDetail(order),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.racingOrange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.racingOrange.withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.store,
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
                                'R\$ ${order.deliveryFee.toStringAsFixed(2)}',
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
      ],
    );
  }

  Widget _buildRiderOrdersList(ThemeData theme, List<DeliveryOrder> orders) {
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
    final myStoreOrders = _orders.where((o) => 
      o.storeId == 'p1' || o.storeId == 'p2' || o.storeId == 'p3'
    ).toList();

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

