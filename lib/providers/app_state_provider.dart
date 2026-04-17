import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/bike.dart';
import '../models/pilot_profile.dart';
import '../services/mock_data_service.dart';

class AppStateProvider extends ChangeNotifier {
  User? _user;
  Bike? _bike;
  bool _isLoggedIn = false;
  bool _hasCompletedSetup = false;
  PilotProfileType? _pilotProfileType;
  DeliveryModerationStatus _deliveryModerationStatus =
      DeliveryModerationStatus.approved;

  User? get user => _user;
  Bike? get bike => _bike;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasCompletedSetup => _hasCompletedSetup;
  PilotProfileType? get pilotProfileType => _pilotProfileType;
  DeliveryModerationStatus get deliveryModerationStatus =>
      _deliveryModerationStatus;

  /// Destino após login por tipo de usuário:
  /// - Lojista/Delivery → MainNavigation
  /// - Casual/Diário/Racing → SocialHomeScreen
  bool get shouldShowSocialHome {
    final u = _user;
    if (u == null) return false;
    if (u.partnerId != null) return false;
    switch (u.userType) {
      case UserType.casual:
      case UserType.diario:
      case UserType.racing:
        return true;
      case UserType.delivery:
      case UserType.lojista:
      case UserType.unknown:
        return false;
    }
  }

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

  void setSetupCompleted(bool value) {
    _hasCompletedSetup = value;
    notifyListeners();
  }

  void setPilotProfileType(PilotProfileType type) {
    _pilotProfileType = type;
    notifyListeners();
  }

  void setDeliveryModerationStatus(DeliveryModerationStatus status) {
    _deliveryModerationStatus = status;
    notifyListeners();
  }

  void initializeMockData() {
    _user = MockDataService.getMockUser();
    _bike = MockDataService.getMockBike();
    _isLoggedIn = true;
    _hasCompletedSetup = true;
    _pilotProfileType = PilotProfileType.diario;
    _deliveryModerationStatus = DeliveryModerationStatus.approved;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _bike = null;
    _isLoggedIn = false;
    _hasCompletedSetup = false;
    _pilotProfileType = null;
    _deliveryModerationStatus = DeliveryModerationStatus.approved;
    notifyListeners();
  }
}
