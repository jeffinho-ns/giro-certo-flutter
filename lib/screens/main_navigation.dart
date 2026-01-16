import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'garage/garage_screen.dart';
import 'ranking/ranking_screen.dart';
import 'manual/manual_screen.dart';
import 'community/community_screen.dart';
import 'maintenance/maintenance_detail_screen.dart';
import 'partners/partners_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/floating_bottom_nav.dart';
import 'sidebars/profile_sidebar.dart';
import '../providers/drawer_provider.dart';

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
  ];

  @override
  void initState() {
    super.initState();
    // Registrar a chave do scaffold no provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
      drawerProvider.setScaffoldKey(_scaffoldKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Ocultar menu na tela de Parceiros (índice 2)
    final showBottomNav = _currentIndex != 2;
    
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
      body: Stack(
        children: [
          _screens[_currentIndex],
          // Bottom navigation flutuante (oculto na tela de parceiros)
          if (showBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
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
