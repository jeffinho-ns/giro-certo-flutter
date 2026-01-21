import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'garage/garage_screen.dart';
import 'ranking/ranking_screen.dart';
import 'manual/manual_screen.dart';
import 'community/community_screen.dart';
import 'maintenance/maintenance_detail_screen.dart';
import 'partners/partners_screen.dart';
import 'delivery/delivery_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/floating_bottom_nav.dart';
import 'sidebars/profile_sidebar.dart';
import '../providers/drawer_provider.dart';
import '../providers/navigation_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const HomeScreen(),
    const MaintenanceDetailScreen(),
    const PartnersScreen(),
    const RankingScreen(),
    const CommunityScreen(),
    const DeliveryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Registrar a chave do scaffold no provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
      drawerProvider.setScaffoldKey(_scaffoldKey);
      
      // Sincronizar o índice inicial com o NavigationProvider
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.navigateTo(_currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    
    // Sincronizar o índice quando o NavigationProvider mudar
    if (navProvider.currentIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = navProvider.currentIndex;
          });
        }
      });
    }
    
    // Menu escondido nas páginas Marketplace (index 2) e Delivery (index 5)
    final shouldHideMenu = _currentIndex == 2 || _currentIndex == 5;
    
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
      body: Stack(
        children: [
          _screens[_currentIndex],
          // Bottom navigation flutuante (escondido em Marketplace e Delivery)
          if (!shouldHideMenu)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNav(
                currentIndex: _currentIndex == 5 ? 99 : _currentIndex, // 99 indica delivery ativo
                onTap: (index) {
                  // Se clicar no botão de delivery (valor especial 99)
                  if (index == 99) {
                    setState(() {
                      _currentIndex = 5;
                    });
                    navProvider.navigateTo(5);
                  } else {
                    setState(() {
                      _currentIndex = index;
                    });
                    navProvider.navigateTo(index);
                  }
                },
              ),
            ),
        ],
      ),
      endDrawer: const ProfileSidebar(),
      endDrawerEnableOpenDragGesture: true,
    );
  }
}
