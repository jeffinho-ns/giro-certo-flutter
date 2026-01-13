import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/bike.dart';
import '../services/mock_data_service.dart';

class AppStateProvider extends ChangeNotifier {
  User? _user;
  Bike? _bike;
  bool _isLoggedIn = false;
  bool _hasCompletedSetup = false;

  User? get user => _user;
  Bike? get bike => _bike;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasCompletedSetup => _hasCompletedSetup;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void setBike(Bike bike) {
    _bike = bike;
    notifyListeners();
  }

  void completeLogin() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void completeSetup() {
    _hasCompletedSetup = true;
    notifyListeners();
  }

  void initializeMockData() {
    _user = MockDataService.getMockUser();
    _bike = MockDataService.getMockBike();
    _isLoggedIn = true;
    _hasCompletedSetup = true;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _bike = null;
    _isLoggedIn = false;
    _hasCompletedSetup = false;
    notifyListeners();
  }
}
