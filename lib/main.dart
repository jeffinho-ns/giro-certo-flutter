import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'utils/theme.dart';
import 'screens/login/splash_screen.dart';
import 'screens/login/register_screen.dart';
import 'screens/login/profile_basic_screen.dart';
import 'screens/login/garage_intro_screen.dart';
import 'screens/login/garage_setup_screen.dart';
import 'screens/login/pilot_profile_screen.dart';
import 'screens/main_navigation.dart';
import 'models/user.dart';
import 'models/bike.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: MaterialApp(
        title: 'Giro Certo',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  int _currentStep = 0;
  String _userName = '';
  String _userEmail = '';
  String _userPassword = '';
  int _userAge = 0;
  String _bikeModel = '';
  String _pilotProfile = 'Urbano';
  String _plate = '';
  int _currentKm = 12450;
  String _oilType = '10W-40 Sintético';
  double _frontTirePressure = 2.5;
  double _rearTirePressure = 2.8;

  void _goToNextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _handleRegister(String name, String email, String password) {
    setState(() {
      _userName = name;
      _userEmail = email;
      _userPassword = password;
      _currentStep++;
    });
  }

  void _handleProfileBasic(String name, int age, String bikeModel) {
    setState(() {
      _userName = name;
      _userAge = age;
      _bikeModel = bikeModel;
      _currentStep++;
    });
  }

  void _handleGarageSetup({
    required String plate,
    required int currentKm,
    required String oilType,
    required double frontTirePressure,
    required double rearTirePressure,
  }) {
    setState(() {
      _plate = plate;
      _currentKm = currentKm;
      _oilType = oilType;
      _frontTirePressure = frontTirePressure;
      _rearTirePressure = rearTirePressure;
      _currentStep++;
    });
  }

  void _handlePilotProfile(String profile) {
    setState(() {
      _pilotProfile = profile;
      _finalizeSetup();
    });
  }

  void _finalizeSetup() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // Criar usuário
    final user = User(
      id: '1',
      name: _userName,
      email: _userEmail,
      age: _userAge,
      pilotProfile: _pilotProfile,
    );
    
    // Criar bike (separar marca e modelo)
    final bikeParts = _bikeModel.split(' ');
    final brand = bikeParts.isNotEmpty ? bikeParts[0] : 'Desconhecida';
    final model = bikeParts.length > 1 ? bikeParts.sublist(1).join(' ') : _bikeModel;
    
    final bike = Bike(
      id: '1',
      model: model,
      brand: brand,
      plate: _plate,
      currentKm: _currentKm,
      oilType: _oilType,
      frontTirePressure: _frontTirePressure,
      rearTirePressure: _rearTirePressure,
    );
    
    appState.setUser(user);
    appState.setBike(bike);
    appState.completeLogin();
    appState.completeSetup();
    
    setState(() {
      _currentStep = 999; // Ir para tela principal
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    
    // Se já está logado, mostra a tela principal
    if (appState.isLoggedIn && appState.hasCompletedSetup) {
      return const MainNavigation();
    }

    // Fluxo de login
    switch (_currentStep) {
      case 0:
        return SplashScreen(onComplete: _goToNextStep);
      case 1:
        return RegisterScreen(onRegister: _handleRegister);
      case 2:
        return ProfileBasicScreen(
          userName: _userName,
          onComplete: _handleProfileBasic,
        );
      case 3:
        return GarageIntroScreen(onContinue: _goToNextStep);
      case 4:
        return GarageSetupScreen(onComplete: _handleGarageSetup);
      case 5:
        return PilotProfileScreen(onSelectProfile: _handlePilotProfile);
      default:
        return const MainNavigation();
    }
  }
}
