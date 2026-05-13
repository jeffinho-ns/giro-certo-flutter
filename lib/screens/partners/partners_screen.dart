import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/partner.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import 'partner_detail_modal.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Todos';
  final List<String> _filters = const [
    'Todos',
    'Lojas',
    'Mecânicos',
    'Mais Próximo',
    'Melhor Avaliação'
  ];
  late TabController _tabController;
  GoogleMapController? _mapController;
  bool _isLoading = false;
  String? _loadError;
  List<Partner> _partners = [];
  Partner? _selectedPartner;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPartners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final partners = await ApiService.getPartners();
      if (!mounted) return;
      setState(() {
        _partners = partners;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  double get _userLatitude {
    final v =
        Provider.of<AppStateProvider>(context, listen: false).user?.currentLat;
    return v ?? -23.5505;
  }

  double get _userLongitude {
    final v =
        Provider.of<AppStateProvider>(context, listen: false).user?.currentLng;
    return v ?? -46.6333;
  }

  List<Partner> _sortedAndFiltered() {
    var list = List<Partner>.from(_partners);

    if (_selectedFilter == 'Lojas') {
      list = list.where((p) => p.type == PartnerType.store).toList();
    } else if (_selectedFilter == 'Mecânicos') {
      list = list.where((p) => p.type == PartnerType.mechanic).toList();
    }

    if (_selectedFilter == 'Mais Próximo') {
      list.sort((a, b) => a
          .distanceTo(_userLatitude, _userLongitude)
          .compareTo(b.distanceTo(_userLatitude, _userLongitude)));
    } else if (_selectedFilter == 'Melhor Avaliação') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return list;
  }

  Set<Marker> _buildMarkers(List<Partner> partners) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('partners_user'),
        position: LatLng(_userLatitude, _userLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      )
    };

    for (final p in partners) {
      markers.add(
        Marker(
          markerId: MarkerId('partner_${p.id}'),
          position: LatLng(p.latitude, p.longitude),
          onTap: () => setState(() => _selectedPartner = p),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            p.type == PartnerType.store
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: p.address,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildRouteLine() {
    final selected = _selectedPartner;
    if (selected == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('partner_route'),
        points: [
          LatLng(_userLatitude, _userLongitude),
          LatLng(selected.latitude, selected.longitude),
        ],
        color: AppColors.racingOrange,
        width: 4,
      )
    };
  }

  void _focusPartnerOnMap(Partner partner) {
    setState(() => _selectedPartner = partner);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(partner.latitude, partner.longitude),
        14.8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredPartners = _sortedAndFiltered();
    final trustedPartners = filteredPartners.where((p) => p.isTrusted).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Parceiros & Mecânicos',
              showBackButton: true,
              onBackPressed: () {
                Provider.of<NavigationProvider>(context, listen: false)
                    .navigateTo(2);
              },
            ),
            _buildFilterChips(theme),
            Material(
              color: theme.scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.racingOrange,
                labelColor: AppColors.racingOrange,
                unselectedLabelColor:
                    theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                tabs: const [
                  Tab(text: 'Mapa'),
                  Tab(text: 'Parceiros Próximos'),
                  Tab(text: 'Mecânicos de Confiança'),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? _buildError(theme)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMapView(filteredPartners, theme),
                            _buildNearbyPartnersView(filteredPartners, theme),
                            _buildTrustedMechanicsView(trustedPartners, theme),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.cloudOff,
              size: 48,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Falha ao carregar parceiros',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPartners,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: AppColors.racingOrange.withOpacity(0.2),
              checkmarkColor: AppColors.racingOrange,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(List<Partner> partners, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_userLatitude, _userLongitude),
              zoom: 12.6,
            ),
            onMapCreated: (controller) => _mapController = controller,
            mapType: MapType.normal,
            markers: _buildMarkers(partners),
            polylines: _buildRouteLine(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Icon(LucideIcons.mapPin,
                        size: 18, color: AppColors.racingOrange),
                    const SizedBox(width: 8),
                    Text('Parceiros próximos',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${partners.length} encontrados',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    final p = partners[index];
                    return SizedBox(
                      width: 270,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _buildPartnerCard(
                          p,
                          theme,
                          compact: true,
                          onOpenRoute: () => _focusPartnerOnMap(p),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyPartnersView(List<Partner> partners, ThemeData theme) {
    if (partners.isEmpty) {
      return Center(
        child: Text('Nenhum parceiro encontrado.',
            style: theme.textTheme.bodyLarge),
      );
    }
    final sorted = List<Partner>.from(partners)
      ..sort((a, b) => a
          .distanceTo(_userLatitude, _userLongitude)
          .compareTo(b.distanceTo(_userLatitude, _userLongitude)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final p = sorted[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPartnerCard(
            p,
            theme,
            onOpenRoute: () => _focusPartnerOnMap(p),
          ),
        );
      },
    );
  }

  Widget _buildTrustedMechanicsView(
      List<Partner> trustedPartners, ThemeData theme) {
    if (trustedPartners.isEmpty) {
      return Center(
        child: Text('Nenhum mecânico de confiança encontrado.',
            style: theme.textTheme.bodyLarge),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trustedPartners.length,
      itemBuilder: (context, index) {
        final partner = trustedPartners[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPartnerCard(
            partner,
            theme,
            onOpenRoute: () => _focusPartnerOnMap(partner),
          ),
        );
      },
    );
  }

  Widget _buildPartnerCard(
    Partner partner,
    ThemeData theme, {
    bool compact = false,
    VoidCallback? onOpenRoute,
  }) {
    final distance = partner.distanceTo(_userLatitude, _userLongitude);

    return InkWell(
      onTap: () => _showPartnerDetail(partner),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: partner.type == PartnerType.store
                        ? AppColors.racingOrange.withOpacity(0.18)
                        : AppColors.neonGreen.withOpacity(0.18),
                  ),
                  child: Icon(
                    partner.type == PartnerType.store
                        ? LucideIcons.store
                        : LucideIcons.wrench,
                    size: 18,
                    color: partner.type == PartnerType.store
                        ? AppColors.racingOrange
                        : AppColors.neonGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    partner.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (partner.isTrusted)
                  const Icon(LucideIcons.shieldCheck,
                      size: 16, color: AppColors.neonGreen),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.star,
                    size: 14, color: AppColors.racingOrange),
                const SizedBox(width: 4),
                Text(partner.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 10),
                const Icon(LucideIcons.navigation, size: 13),
                const SizedBox(width: 4),
                Text('${distance.toStringAsFixed(1)} km',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: onOpenRoute,
              child: Row(
                children: [
                  Icon(LucideIcons.mapPin,
                      size: 13, color: AppColors.racingOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      partner.address,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.racingOrange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: partner.specialties
                  .take(compact ? 2 : 4)
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(s, style: theme.textTheme.labelSmall),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showPartnerDetail(Partner partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerDetailModal(partner: partner),
    );
  }
}
