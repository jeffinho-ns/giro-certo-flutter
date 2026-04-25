import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/drawer_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/social_feed_provider.dart';
import 'providers/notifications_count_provider.dart';
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
import 'screens/social/social_home_screen.dart';
import 'models/user.dart';
import 'models/bike.dart';
import 'models/motorcycle_model.dart';
import 'models/pilot_profile.dart';
import 'models/garage_setup_result.dart';
import 'models/vehicle_type.dart';
import 'services/app_preload_service.dart';
import 'services/onboarding_service.dart';
import 'services/motorcycle_data_service.dart';
import 'app_navigator_key.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart' as push;
import 'services/notification_service.dart' as local_notifications;
import 'widgets/realtime_connection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await push.initializeFirebase();
  await local_notifications.initializeLocalNotifications();
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
        ChangeNotifierProvider(create: (_) => SocialFeedProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsCountProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
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
  bool _isBicycle = false;
  String _bicycleCor = '';
  String _bicycleObs = '';
  MotorcycleModel? _selectedMotorcycle;
  String? _selectedMotorcycleImagePath;
  String _plate = 'ABC-1234';
  int _currentKm = 12450;
  String _oilType = '10W-40 Sintético';
  double _frontTirePressure = 2.5;
  double _rearTirePressure = 2.8;
  bool _isPreloading = true;
  bool _isRegisteringInProgress = false;
  /// Só entra na Home após o usuario deslizar na splash nesta abertura da app (ou apos logout, nova splash).
  bool _splashCompletedThisSession = false;
  AppStateProvider? _appStateRef;

  @override
  void initState() {
    super.initState();
    _appStateRef = Provider.of<AppStateProvider>(context, listen: false);
    _appStateRef!.addListener(_onAppStateForSplashReset);
    _initializeAuthFlow();
  }

  @override
  void dispose() {
    _appStateRef?.removeListener(_onAppStateForSplashReset);
    super.dispose();
  }

  void _onAppStateForSplashReset() {
    final appState = _appStateRef;
    if (appState == null) return;
    if (!appState.resetAuthSplashAfterLogout) return;
    appState.clearResetAuthSplashAfterLogout();
    if (!mounted) return;
    setState(() {
      _splashCompletedThisSession = false;
      _currentStep = _stepSplash;
    });
  }

  Future<void> _initializeAuthFlow() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    await Future.wait([
      _preloadAssets(),
      appState.loadSession(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);
    // Fluxo de onboarding incompleto continua apos o deslize na splash (_onSplashComplete).
    if (!mounted) return;
    setState(() {
      _isPreloading = false;
    });
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
      debugPrint('Erro ao pre-carregar assets: $e');
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

  void _onSplashComplete() {
    if (!mounted) return;
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    setState(() {
      _splashCompletedThisSession = true;
    });
    if (appState.isLoggedIn &&
        appState.hasCompletedSetup &&
        appState.user != null) {
      return;
    }
    if (appState.isLoggedIn && !appState.hasCompletedSetup) {
      _handleLoginAsync();
      return;
    }
    _setStep(_stepLogin);
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
    } catch (e) {
      debugPrint('Falha ao buscar onboarding no servidor: $e');
      // fallback para armazenamento local
    }

    final savedStep = serverStep ?? await OnboardingService.getSavedStep();
    final restoredStep = (savedStep != null && savedStep >= _stepGarageIntro)
        ? savedStep
        : _stepGarageIntro;

    final savedMotorcycleId = await OnboardingService.getSelectedMotorcycleId();
    if (savedMotorcycleId == OnboardingService.bicycleCatalogId) {
      _isBicycle = true;
      _selectedMotorcycle = null;
      _selectedMotorcycleImagePath = null;
      final bi = await OnboardingService.getBicycleGarageInfo();
      if (bi != null) {
        _bikeBrand = bi.brand;
        _bicycleCor = bi.cor;
        _bicycleObs = bi.obs;
        if (bi.aro.isNotEmpty) {
          _bikeModel = 'Aro ${bi.aro}';
        }
      }
    } else if (savedMotorcycleId != null) {
      _isBicycle = false;
      _selectedMotorcycle =
          MotorcycleDataService.tryGetMotorcycleById(savedMotorcycleId) ??
              MotorcycleDataService.findMotorcycleById(savedMotorcycleId);
      _selectedMotorcycleImagePath =
          await OnboardingService.getSelectedMotorcycleImagePath();
      _bikeBrand = _selectedMotorcycle?.brand ?? _bikeBrand;
      _bikeModel = _selectedMotorcycle?.model ?? _bikeModel;
    }

    if (!mounted) return;
    _setStep(restoredStep);

    final savedPilotType = await OnboardingService.getPilotType();
    if (savedPilotType != null && appState.pilotProfileType == null) {
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

  void _handleGarageSetup(GarageSetupResult r) {
    if (r.mode == AppVehicleType.bicycle) {
      setState(() {
        _isBicycle = true;
        _selectedMotorcycle = null;
        _selectedMotorcycleImagePath = r.resolvedImagePath;
        _bikeBrand = r.brand;
        _bikeModel = r.model;
        _plate = r.plate;
        _currentKm = r.currentKm;
        _oilType = r.oilType;
        _frontTirePressure = r.frontTirePressure;
        _rearTirePressure = r.rearTirePressure;
        _bicycleCor = r.bicycleCor ?? '';
        _bicycleObs = r.bicycleObservacao ?? '';
      });
      OnboardingService.saveBicycleGarageInfo(
        brand: r.brand,
        aro: r.bicycleAro ?? '',
        cor: r.bicycleCor ?? '',
        observacao: r.bicycleObservacao ?? '',
      );
      OnboardingService.saveMotorcycleSelection(
        motorcycleId: OnboardingService.bicycleCatalogId,
        imagePath: r.resolvedImagePath,
      );
    } else {
      final m = r.motorcycle;
      if (m == null) return;
      setState(() {
        _isBicycle = false;
        _bicycleCor = '';
        _bicycleObs = '';
        _bikeBrand = r.brand;
        _bikeModel = r.model;
        _plate = r.plate;
        _currentKm = r.currentKm;
        _oilType = r.oilType;
        _frontTirePressure = r.frontTirePressure;
        _rearTirePressure = r.rearTirePressure;
        _selectedMotorcycle = m;
        _selectedMotorcycleImagePath = r.resolvedImagePath;
      });
      OnboardingService.clearBicycleGarageInfo();
      OnboardingService.saveMotorcycleSelection(
        motorcycleId: m.id,
        imagePath: r.resolvedImagePath,
      );
    }
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

  void _handleDeliveryRegistrationComplete(DeliveryRegistrationDetails details) {
    _handleDeliveryRegistrationCompleteAsync(details);
  }

  Future<void> _handleDeliveryRegistrationCompleteAsync(
      DeliveryRegistrationDetails details) async {
    await _finalizeSetup(
      deliveryStatus: DeliveryModerationStatus.pending,
      deliveryDetails: details,
    );
  }

  Future<void> _finalizeSetup({
    required DeliveryModerationStatus deliveryStatus,
    GarageSetupDetails? garageDetails,
    DeliveryRegistrationDetails? deliveryDetails,
  }) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final resolvedProfile = _pilotProfileType ??
        appState.pilotProfileType ??
        PilotProfileType.diario;

    final existingUser = appState.user;
    final user = existingUser != null
        ? existingUser.copyWith(
            pilotProfile: resolvedProfile.apiValue,
            userType: parseUserType(resolvedProfile.apiValue),
          )
        : User(
            id: '1',
            name: _userName,
            email: _userEmail,
            age: _userAge,
            pilotProfile: resolvedProfile.apiValue,
            userType: parseUserType(resolvedProfile.apiValue),
          );

    final isBike = _isBicycle;
    final brand = _bikeBrand.isNotEmpty
        ? _bikeBrand
        : _selectedMotorcycle?.brand ?? 'Desconhecida';
    final model = _bikeModel.isNotEmpty
        ? _bikeModel
        : _selectedMotorcycle?.model ?? 'Modelo';
    final rawPlate = (deliveryDetails?.plateLicense ?? _plate).trim();
    final plate = rawPlate.isEmpty
        ? (isBike ? 'S/N' : 'ABC-1234')
        : rawPlate;
    final currentKm = deliveryDetails?.currentKilometers ?? _currentKm;
    final vPhoto = deliveryDetails?.vehiclePhotoUrl;
    final mainPhoto = vPhoto ??
        _selectedMotorcycleImagePath ??
        _selectedMotorcycle?.modelImagePath;
    final vType = isBike ? AppVehicleType.bicycle : AppVehicleType.motorcycle;
    final accessories =
        isBike && (deliveryDetails?.equipments.isNotEmpty == true)
            ? deliveryDetails!.equipments
            : (garageDetails?.accessories ?? const []);

    final bike = Bike(
      id: '1',
      model: model,
      brand: brand,
      plate: plate,
      currentKm: currentKm,
      oilType: isBike ? '—' : _oilType,
      frontTirePressure: isBike ? 0 : _frontTirePressure,
      rearTirePressure: isBike ? 0 : _rearTirePressure,
      photoUrl: mainPhoto,
      vehiclePhotoUrl: vPhoto ?? (isBike ? mainPhoto : null),
      nickname: garageDetails?.nickname ?? model,
      ridingStyle: garageDetails?.ridingStyle,
      accessories: accessories,
      nextUpgrade: isBike
          ? (_bicycleObs.isNotEmpty ? _bicycleObs : null)
          : garageDetails?.nextUpgrade,
      preferredColor: isBike
          ? (_bicycleCor.isNotEmpty ? _bicycleCor : null)
          : garageDetails?.colorLabel,
      additionalPhotos: () {
        final s = <String>{};
        void add(String? u) {
          if (u != null && u.trim().isNotEmpty) s.add(u);
        }
        add(vPhoto);
        add(mainPhoto);
        if (!isBike) {
          add(_selectedMotorcycleImagePath);
          if (_selectedMotorcycle?.modelImagePath != null &&
              _selectedMotorcycle!.modelImagePath != _selectedMotorcycleImagePath) {
            add(_selectedMotorcycle!.modelImagePath);
          }
        }
        return s.toList();
      }(),
      vehicleType: vType,
    );

    appState.setUser(user);
    try {
      final persistedBike = await ApiService.createBike(
        model: bike.model,
        brand: bike.brand,
        plate: bike.plate,
        currentKm: bike.currentKm,
        oilType: bike.oilType,
        frontTirePressure: bike.frontTirePressure,
        rearTirePressure: bike.rearTirePressure,
        photoUrl: bike.photoUrl,
        vehiclePhotoUrl: bike.vehiclePhotoUrl,
        nickname: bike.nickname,
        ridingStyle: bike.ridingStyle,
        accessories: bike.accessories,
        nextUpgrade: bike.nextUpgrade,
        preferredColor: bike.preferredColor,
        galleryUrls: bike.additionalPhotos,
        vehicleType: bike.vehicleType,
      );
      appState.setBike(persistedBike);
    } catch (_) {
      appState.setBike(bike);
    }
    appState.setPilotProfileType(resolvedProfile);
    appState.setDeliveryModerationStatus(deliveryStatus);
    appState.completeLogin();
    appState.completeSetup();
    if (deliveryDetails != null) {
      await OnboardingService.setLastKnownDeliveryRegStatus('PENDING');
    }
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

    final sessionStillLoading =
        _isPreloading || appState.isSessionLoading || !appState.hasHydratedSession;
    if (sessionStillLoading) {
      return SplashScreen(
        key: const ValueKey<String>('splash-loading'),
        interactionEnabled: false,
        onComplete: () {},
      );
    }

    // Fluxo de navegação: Login → Setup → Home por tipo de usuário
    // Delivery → home mapa (MainNavigation); Lojista → home lojista (MainNavigation); Casual/Diário/Racing → home social
    if (appState.isLoggedIn &&
        appState.hasCompletedSetup &&
        appState.user != null &&
        _splashCompletedThisSession) {
      final userId = appState.user!.id;
      if (appState.shouldShowSocialHome) {
        return RealtimeConnection(userId: userId, child: const SocialHomeScreen());
      }
      return RealtimeConnection(userId: userId, child: const MainNavigation());
    }

    Widget stepScreen;
    switch (_currentStep) {
      case _stepSplash:
        stepScreen = SplashScreen(
          key: const ValueKey<String>('splash-interactive'),
          interactionEnabled: true,
          onComplete: _onSplashComplete,
        );
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
          onlyDeliveryForBicycle: _isBicycle,
          onContinue: _handlePilotProfileContinue,
        );
        break;
      case _stepGarageDetail:
        if (_isBicycle) {
          stepScreen = DeliveryRegistrationScreen(
            pilotType: _pilotProfileType ?? PilotProfileType.delivery,
            isBicycleCourier: true,
            onSubmit: _handleDeliveryRegistrationComplete,
            onBack: () => _setStep(_stepPilotProfile),
          );
        } else if (_selectedMotorcycle == null) {
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
          isBicycleCourier: _isBicycle,
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
