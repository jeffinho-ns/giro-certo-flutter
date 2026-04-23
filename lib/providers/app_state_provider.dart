import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/bike.dart';
import '../models/pilot_profile.dart';
import '../services/mock_data_service.dart';
import '../services/api_service.dart';
import '../services/onboarding_service.dart';

class AppStateProvider extends ChangeNotifier {
  User? _user;
  Bike? _bike;
  bool _isLoggedIn = false;
  bool _hasCompletedSetup = false;
  bool _isSessionLoading = false;
  bool _hasHydratedSession = false;
  /// Após [logout], o [AuthWrapper] volta a exibir a splash antes do login.
  bool _resetAuthSplashAfterLogout = false;
  PilotProfileType? _pilotProfileType;
  DeliveryModerationStatus _deliveryModerationStatus =
      DeliveryModerationStatus.approved;

  User? get user => _user;
  Bike? get bike => _bike;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasCompletedSetup => _hasCompletedSetup;
  bool get isSessionLoading => _isSessionLoading;
  bool get hasHydratedSession => _hasHydratedSession;
  bool get resetAuthSplashAfterLogout => _resetAuthSplashAfterLogout;
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
    _isSessionLoading = false;
    _hasHydratedSession = true;
    _pilotProfileType = PilotProfileType.diario;
    _deliveryModerationStatus = DeliveryModerationStatus.approved;
    notifyListeners();
  }

  Future<void> loadSession() async {
    _isSessionLoading = true;
    notifyListeners();

    try {
      await ApiService.warmupAuthToken();
      final hasToken = await ApiService.hasStoredToken();
      if (!hasToken) {
        _user = null;
        _bike = null;
        _isLoggedIn = false;
        _hasCompletedSetup = false;
        _pilotProfileType = null;
        _deliveryModerationStatus = DeliveryModerationStatus.approved;
        return;
      }

      final sessionUser = await ApiService.getCurrentUser();
      _user = sessionUser;
      _isLoggedIn = true;
      _pilotProfileType = _mapPilotProfileType(sessionUser.pilotProfile);
      try {
        final bikes = await ApiService.getMyBikes();
        _bike = bikes.isNotEmpty ? bikes.first : null;
      } catch (_) {
        // mantém o estado atual da bike em caso de falha de rede
      }
      // Delivery: se o admin já aprovou uma vez, fica persistido (como "e-mail verificado")
      // e não voltamos a mostrar "em análise" até o primeiro fetch por hasVerifiedDocuments.
      if (sessionUser.userType == UserType.delivery) {
        final cached = await OnboardingService.getDeliveryStatus();
        if (cached == DeliveryModerationStatus.approved) {
          _deliveryModerationStatus = DeliveryModerationStatus.approved;
        } else {
          _deliveryModerationStatus = sessionUser.hasVerifiedDocuments
              ? DeliveryModerationStatus.approved
              : DeliveryModerationStatus.pending;
        }
      } else {
        _deliveryModerationStatus = sessionUser.hasVerifiedDocuments
            ? DeliveryModerationStatus.approved
            : DeliveryModerationStatus.pending;
      }

      // Regra de produto: usuário já existente que conseguiu autenticar
      // deve ir direto para a home do perfil; onboarding só no fluxo de cadastro.
      if (sessionUser.userType != UserType.unknown ||
          sessionUser.onboardingCompleted) {
        _hasCompletedSetup = true;
      } else {
        _hasCompletedSetup = await ApiService.userHasBikes();
      }
    } catch (e) {
      debugPrint('Falha ao reidratar sessão: $e');
      await ApiService.logout();
      _user = null;
      _bike = null;
      _isLoggedIn = false;
      _hasCompletedSetup = false;
      _pilotProfileType = null;
      _deliveryModerationStatus = DeliveryModerationStatus.approved;
    } finally {
      _isSessionLoading = false;
      _hasHydratedSession = true;
      notifyListeners();
    }
  }

  PilotProfileType? _mapPilotProfileType(String? profile) {
    final userType = parseUserType(profile);
    switch (userType) {
      case UserType.casual:
        return PilotProfileType.casual;
      case UserType.diario:
        return PilotProfileType.diario;
      case UserType.racing:
        return PilotProfileType.racing;
      case UserType.delivery:
        return PilotProfileType.delivery;
      case UserType.lojista:
      case UserType.unknown:
        return null;
    }
  }

  void logout() {
    _user = null;
    _bike = null;
    _isLoggedIn = false;
    _hasCompletedSetup = false;
    _isSessionLoading = false;
    _hasHydratedSession = true;
    _pilotProfileType = null;
    _deliveryModerationStatus = DeliveryModerationStatus.approved;
    _resetAuthSplashAfterLogout = true;
    notifyListeners();
  }

  void clearResetAuthSplashAfterLogout() {
    _resetAuthSplashAfterLogout = false;
  }
}
