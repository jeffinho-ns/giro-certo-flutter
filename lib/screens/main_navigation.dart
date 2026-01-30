import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'home/partner_home_screen.dart';
import 'garage/garage_screen.dart';
import 'ranking/ranking_screen.dart';
import 'community/community_screen.dart';
import 'momentos/momentos_screen.dart';
import '../widgets/floating_bottom_nav.dart';
import '../widgets/menu_grid_modal.dart';
import 'sidebars/profile_sidebar.dart';
import '../providers/drawer_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/app_state_provider.dart';

/// Navegação principal com 5 destinos:
/// 0 = Chat (CommunityScreen), 1 = Eventos (RankingScreen), 2 = Menu/Mapa (HomeScreen),
/// 3 = Momentos (MomentosScreen), 4 = Garagem (GarageScreen).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // Inicial: Hub Mapa (Menu)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _buildScreens(bool isPartner) {
    return [
      const CommunityScreen(),   // 0 Chat
      const RankingScreen(),     // 1 Eventos
      isPartner ? const PartnerHomeScreen() : const HomeScreen(), // 2: Lojista = dashboard; Motociclista = mapa
      const MomentosScreen(),    // 3 Momentos
      const GarageScreen(),      // 4 Garagem
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
      drawerProvider.setScaffoldKey(_scaffoldKey);
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.navigateTo(_currentIndex);
    });
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _openMenuModal();
      return;
    }
    setState(() => _currentIndex = index);
    Provider.of<NavigationProvider>(context, listen: false).navigateTo(index);
  }

  void _openMenuModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => MenuGridModal(
        onClose: () {},
        onNavigateToIndex: (index) {
          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
          setState(() => _currentIndex = index);
          navProvider.navigateTo(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final isPartner = appState.user?.isPartner ?? false;
    final screens = _buildScreens(isPartner);

    if (navProvider.currentIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentIndex = navProvider.currentIndex);
        }
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawerEnableOpenDragGesture: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNav(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
      endDrawer: const ProfileSidebar(),
      endDrawerEnableOpenDragGesture: true,
    );
  }
}
