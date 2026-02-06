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
import 'screens/login/pilot_profile_select_screen.dart';
import 'screens/login/garage_setup_detail_screen.dart';
import 'screens/login/delivery_registration_screen.dart';
import 'screens/main_navigation.dart';
import 'models/user.dart';
import 'models/bike.dart';
import 'models/motorcycle_model.dart';
import 'models/pilot_profile.dart';
import 'services/app_preload_service.dart';
import 'services/onboarding_service.dart';
import 'services/motorcycle_data_service.dart';
import 'services/api_service.dart';
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
  static const int _stepSplash = 0;
  static const int _stepLogin = 1;
  static const int _stepRegister = 2;
  static const int _stepGarageIntro = 4;
  static const int _stepGarageSelect = 5;
  static const int _stepPilotProfile = 6;
  static const int _stepGarageDetail = 7;
  static const int _stepDeliveryRegistration = 8;
  static const int _stepHome = 999;

  int _currentStep = _stepSplash;
  String _userName = '';
  String _userEmail = '';
  String _userPassword = '';
  int _userAge = 0;
  String _bikeBrand = '';
  String _bikeModel = '';
  String _pilotProfile = 'Diario';
  PilotProfileType? _pilotProfileType;
  MotorcycleModel? _selectedMotorcycle;
  String? _selectedMotorcycleImagePath;
  String _plate = 'ABC-1234';
  int _currentKm = 12450;
  String _oilType = '10W-40 Sintético';
  double _frontTirePressure = 2.5;
  double _rearTirePressure = 2.8;
  bool _isPreloading = true;
  bool _isRegisteringInProgress = false;

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

  void _setStep(int step) {
    setState(() {
      _currentStep = step;
    });
    if (step >= _stepGarageIntro && step != _stepHome) {
      OnboardingService.saveStep(step);
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (appState.isLoggedIn) {
        ApiService.updateOnboardingStatus(step: step);
      }
    }
  }

  void _goToNextStep() {
    _setStep(_currentStep + 1);
  }

  void _handleLogin() {
    _handleLoginAsync();
  }

  Future<void> _handleLoginAsync() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    if (appState.hasCompletedSetup) {
      setState(() => _currentStep = _stepHome);
      return;
    }

    int? serverStep;
    try {
      final onboarding = await ApiService.getOnboardingStatus();
      final completed = onboarding['onboardingCompleted'] as bool? ?? false;
      if (completed) {
        appState.setSetupCompleted(true);
        if (mounted) {
          setState(() => _currentStep = _stepHome);
        }
        return;
      }
      serverStep = onboarding['onboardingStep'] as int?;
    } catch (_) {
      // fallback para armazenamento local
    }

    final savedStep = serverStep ?? await OnboardingService.getSavedStep();
    final restoredStep =
        (savedStep != null && savedStep >= _stepGarageIntro)
            ? savedStep
            : _stepGarageIntro;

    final savedMotorcycleId = await OnboardingService.getSelectedMotorcycleId();
    if (savedMotorcycleId != null) {
      _selectedMotorcycle =
          MotorcycleDataService.findMotorcycleById(savedMotorcycleId);
      _selectedMotorcycleImagePath =
          await OnboardingService.getSelectedMotorcycleImagePath();
      _bikeBrand = _selectedMotorcycle?.brand ?? _bikeBrand;
      _bikeModel = _selectedMotorcycle?.model ?? _bikeModel;
    }

    if (!mounted) return;
    if (!mounted) return;
    _setStep(restoredStep);

    final savedPilotType = await OnboardingService.getPilotType();
    if (savedPilotType != null) {
      _pilotProfileType = savedPilotType;
      appState.setPilotProfileType(savedPilotType);
      _pilotProfile = savedPilotType.label;
    }

    final savedDeliveryStatus = await OnboardingService.getDeliveryStatus();
    if (savedDeliveryStatus != null) {
      appState.setDeliveryModerationStatus(savedDeliveryStatus);
    }
  }

  void _handleRegister() {
    _setStep(_stepRegister);
  }

  void _handleRegisterComplete(
      String name, String email, String password, int age) {
    _handleRegisterCompleteAsync(name, email, password, age);
  }

  Future<void> _handleRegisterCompleteAsync(
      String name, String email, String password, int age) async {
    // Prevenir múltiplos registros simultâneos
    if (_isRegisteringInProgress) {
      print('⚠️ Registro já em andamento, ignorando nova requisição');
      return;
    }

    _isRegisteringInProgress = true;

    try {
      print('📝 Iniciando registro de usuário: $email');
      
      // Chamar API de registro
      final registerResponse = await ApiService.register(
        name: name,
        email: email,
        password: password,
        age: age,
      );
      
      print('✅ Registro realizado com sucesso: $registerResponse');

      // Extrair usuário e token da resposta
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      if (registerResponse['user'] != null) {
        final user = User.fromJson(registerResponse['user']);
        appState.setUser(user);
        appState.completeLogin();
        print('🔐 Usuário salvo no AppState: ${user.email}');
      }

      // Salvar dados locais
      setState(() {
        _userName = name;
        _userEmail = email;
        _userPassword = password;
        _userAge = age;
      });

      if (mounted) {
        _setStep(_stepGarageIntro);
      }
    } catch (e) {
      print('❌ Erro ao registrar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar: $e')),
        );
      }
    } finally {
      _isRegisteringInProgress = false;
    }
  }

  void _handleGarageSetup({
    required MotorcycleModel motorcycle,
    String? resolvedImagePath,
    required String brand,
    required String model,
    required String plate,
    required int currentKm,
    required String oilType,
    required double frontTirePressure,
    required double rearTirePressure,
  }) {
    setState(() {
      _bikeBrand = brand;
      _bikeModel = model;
      _plate = plate;
      _currentKm = currentKm;
      _oilType = oilType;
      _frontTirePressure = frontTirePressure;
      _rearTirePressure = rearTirePressure;
      _selectedMotorcycle = motorcycle;
      _selectedMotorcycleImagePath = resolvedImagePath;
    });
    OnboardingService.saveMotorcycleSelection(
      motorcycleId: motorcycle.id,
      imagePath: resolvedImagePath,
    );
    _setStep(_stepPilotProfile);
  }

  void _handlePilotProfileContinue(PilotProfileType profileType) {
    _pilotProfileType = profileType;
    _pilotProfile = profileType.label;
    OnboardingService.savePilotType(profileType);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.setPilotProfileType(profileType);
    if (profileType.isDelivery) {
      _setStep(_stepDeliveryRegistration);
    } else {
      _setStep(_stepGarageDetail);
    }
  }

  void _handleGarageDetailComplete(GarageSetupDetails details) {
    _handleGarageDetailCompleteAsync(details);
  }

  Future<void> _handleGarageDetailCompleteAsync(
      GarageSetupDetails details) async {
    await _finalizeSetup(
      garageDetails: details,
      deliveryStatus: DeliveryModerationStatus.approved,
    );
  }

  void _handleDeliveryRegistrationComplete(DeliveryRegistrationDetails _) {
    _handleDeliveryRegistrationCompleteAsync();
  }

  Future<void> _handleDeliveryRegistrationCompleteAsync() async {
    await _finalizeSetup(
      deliveryStatus: DeliveryModerationStatus.pending,
    );
  }

  Future<void> _finalizeSetup({
    required DeliveryModerationStatus deliveryStatus,
    GarageSetupDetails? garageDetails,
  }) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final resolvedProfile =
        _pilotProfileType ?? appState.pilotProfileType ?? PilotProfileType.diario;

    final existingUser = appState.user;
    final user = existingUser != null
        ? existingUser.copyWith(pilotProfile: resolvedProfile.label)
        : User(
            id: '1',
            name: _userName,
            email: _userEmail,
            age: _userAge,
            pilotProfile: resolvedProfile.label,
          );

    final brand = _bikeBrand.isNotEmpty
        ? _bikeBrand
        : _selectedMotorcycle?.brand ?? 'Desconhecida';
    final model = _bikeModel.isNotEmpty
        ? _bikeModel
        : _selectedMotorcycle?.model ?? 'Modelo';

    final bike = Bike(
      id: '1',
      model: model,
      brand: brand,
      plate: _plate,
      currentKm: _currentKm,
      oilType: _oilType,
      frontTirePressure: _frontTirePressure,
      rearTirePressure: _rearTirePressure,
      nickname: garageDetails?.nickname ?? model,
      ridingStyle: garageDetails?.ridingStyle,
      accessories: garageDetails?.accessories ?? const [],
      nextUpgrade: garageDetails?.nextUpgrade,
      preferredColor: garageDetails?.colorLabel,
    );

    appState.setUser(user);
    appState.setBike(bike);
    appState.setPilotProfileType(resolvedProfile);
    appState.setDeliveryModerationStatus(deliveryStatus);
    appState.completeLogin();
    appState.completeSetup();
    await OnboardingService.completeOnboarding();
    await OnboardingService.saveDeliveryStatus(deliveryStatus);
    await ApiService.updateOnboardingStatus(
      completed: true,
      step: _stepHome,
    );

    if (mounted) {
      setState(() {
        _currentStep = _stepHome;
      });
    }
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

    Widget stepScreen;
    switch (_currentStep) {
      case _stepSplash:
        stepScreen = SplashScreen(onComplete: _goToNextStep);
        break;
      case _stepLogin:
        stepScreen = LoginScreen(
          onLogin: _handleLogin,
          onRegister: _handleRegister,
        );
        break;
      case _stepRegister:
        stepScreen = RegisterScreen(onRegister: _handleRegisterComplete);
        break;
      case _stepGarageIntro:
        stepScreen = GarageIntroScreen(onContinue: _goToNextStep);
        break;
      case _stepGarageSelect:
        stepScreen = GarageSetupScreen(onComplete: _handleGarageSetup);
        break;
      case _stepPilotProfile:
        stepScreen = PilotProfileSelectScreen(
          initialSelection: _pilotProfileType ?? appState.pilotProfileType,
          onContinue: _handlePilotProfileContinue,
        );
        break;
      case _stepGarageDetail:
        if (_selectedMotorcycle == null) {
          stepScreen = GarageSetupScreen(onComplete: _handleGarageSetup);
        } else {
          stepScreen = GarageSetupDetailScreen(
            motorcycle: _selectedMotorcycle!,
            motorcycleImagePath: _selectedMotorcycleImagePath,
            pilotType: _pilotProfileType ?? PilotProfileType.diario,
            onFinish: _handleGarageDetailComplete,
            onBack: () => _setStep(_stepPilotProfile),
          );
        }
        break;
      case _stepDeliveryRegistration:
        stepScreen = DeliveryRegistrationScreen(
          pilotType: _pilotProfileType ?? PilotProfileType.delivery,
          onSubmit: _handleDeliveryRegistrationComplete,
          onBack: () => _setStep(_stepPilotProfile),
        );
        break;
      default:
        stepScreen = LoginScreen(
          onLogin: _handleLogin,
          onRegister: _handleRegister,
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_currentStep),
        child: stepScreen,
      ),
    );
  }
}
