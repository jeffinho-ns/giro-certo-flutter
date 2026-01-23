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
import '../providers/app_state_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _getScreens(bool isPartner) {
    if (isPartner) {
      // Para lojistas: apenas Home e Delivery
      return [
        const HomeScreen(),
        const SizedBox.shrink(), // Manutenção (oculto)
        const SizedBox.shrink(), // Parceiros (oculto)
        const SizedBox.shrink(), // Ranking (oculto)
        const SizedBox.shrink(), // Comunidade (oculto)
        const DeliveryScreen(),
      ];
    } else {
      // Para motociclistas: todas as telas
      return [
        const HomeScreen(),
        const MaintenanceDetailScreen(),
        const PartnersScreen(),
        const RankingScreen(),
        const CommunityScreen(),
        const DeliveryScreen(),
      ];
    }
  }

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
    final appState = Provider.of<AppStateProvider>(context);
    final isPartner = appState.user?.isPartner ?? false;
    
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
    
    // Para lojistas, só mostrar menu na Home (index 0) e Delivery (index 5)
    // Para motociclistas, esconder em Marketplace (index 2) e Delivery (index 5)
    final shouldHideMenu = isPartner 
        ? (_currentIndex != 0 && _currentIndex != 5)
        : (_currentIndex == 2 || _currentIndex == 5);
    
    final screens = _getScreens(isPartner);
    
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
      body: Stack(
        children: [
          screens[_currentIndex],
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
