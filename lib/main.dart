import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/drawer_provider.dart';
import 'providers/navigation_provider.dart';
import 'utils/theme.dart';
import 'screens/login/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';
import 'screens/login/garage_intro_screen.dart';
import 'screens/login/garage_setup_screen.dart';
import 'screens/login/pilot_profile_screen.dart';
import 'screens/main_navigation.dart';
import 'models/user.dart';
import 'models/bike.dart';
import 'services/app_preload_service.dart';
import 'services/motorcycle_data_service.dart';
import 'utils/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => DrawerProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Giro Certo',
            theme: AppTheme.getLightTheme(
              primaryColor: themeProvider.primaryColor,
              primaryLightColor: themeProvider.primaryLightColor,
            ),
            darkTheme: AppTheme.getDarkTheme(
              primaryColor: themeProvider.primaryColor,
              primaryLightColor: themeProvider.primaryLightColor,
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
          );
        },
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
  bool _isPreloading = true;

  @override
  void initState() {
    super.initState();
    _preloadAssets();
  }

  Future<void> _preloadAssets() async {
    // Aguardar o primeiro frame antes de pré-carregar
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    // Pré-carregar todos os assets com timeout
    try {
      await AppPreloadService.preloadAllAssets(context).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          // Timeout - continua mesmo sem pré-carregar tudo
        },
      );
    } catch (e) {
      // Continua mesmo se houver erro
    }

    if (mounted) {
      setState(() {
        _isPreloading = false;
      });
    }
  }

  void _goToNextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _handleLogin() {
    // O LoginScreen agora faz o login e salva o usuário diretamente
    // Apenas navegar para a home
    setState(() {
      _currentStep = 999;
    });
  }

  void _handleRegister() {
    setState(() {
      _currentStep = 2;
    });
  }

  void _handleRegisterComplete(
      String name, String email, String password, int age) {
    setState(() {
      _userName = name;
      _userEmail = email;
      _userPassword = password;
      _userAge = age;
      _currentStep = 4;
    });
  }

  void _handleGarageSetup({
    required String brand,
    required String model,
    required String plate,
    required int currentKm,
    required String oilType,
    required double frontTirePressure,
    required double rearTirePressure,
  }) {
    setState(() {
      _bikeModel = '$brand $model';
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

    final user = User(
      id: '1',
      name: _userName,
      email: _userEmail,
      age: _userAge,
      pilotProfile: _pilotProfile,
    );

    final bikeParts = _bikeModel.split(' ');
    final brand = bikeParts.isNotEmpty ? bikeParts[0] : 'Desconhecida';
    final model =
        bikeParts.length > 1 ? bikeParts.sublist(1).join(' ') : _bikeModel;

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
      _currentStep = 999;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isPreloading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor,
                      theme.scaffoldBackgroundColor,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.lightBackground,
                      AppColors.lightSurface,
                    ],
                  ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: themeProvider.primaryColor,
            ),
          ),
        ),
      );
    }

    // Fluxo de navegação correto: SplashScreen → Login → Setup → Home
    if (appState.isLoggedIn && appState.hasCompletedSetup) {
      return const MainNavigation();
    }

    switch (_currentStep) {
      case 0:
        return SplashScreen(onComplete: _goToNextStep);
      case 1:
        return LoginScreen(
          onLogin: _handleLogin,
          onRegister: _handleRegister,
        );
      case 2:
        return RegisterScreen(onRegister: _handleRegisterComplete);
      case 4:
        return GarageIntroScreen(onContinue: _goToNextStep);
      case 5:
        return GarageSetupScreen(onComplete: _handleGarageSetup);
      case 6:
        return PilotProfileScreen(onSelectProfile: _handlePilotProfile);
      default:
        return LoginScreen(
          onLogin: _handleLogin,
          onRegister: _handleRegister,
        );
    }
  }
}
