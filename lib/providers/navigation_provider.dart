import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;
  
  void navigateTo(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void navigateToHome() {
    navigateTo(0);
  }

  /// Hub principal com mapa: [HomeScreen] para motociclista ou [PartnerHomeScreen] para lojista.
  void navigateToRiderOrPartnerHub() {
    navigateTo(2);
  }
}

