import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'home/home_screen.dart';
import 'garage/garage_screen.dart';
import 'ranking/ranking_screen.dart';
import 'manual/manual_screen.dart';
import 'community/community_screen.dart';
import 'maintenance/maintenance_detail_screen.dart';
import '../utils/colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MaintenanceDetailScreen(),
    const RankingScreen(),
    const ManualScreen(),
    const CommunityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.darkGray,
        selectedItemColor: AppColors.racingOrange,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.wrench),
            label: 'Manutenção',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.trophy),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.bookOpen),
            label: 'Manual',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.users),
            label: 'Comunidade',
          ),
        ],
      ),
    );
  }
}
