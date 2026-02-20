import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../utils/colors.dart';
import '../../services/api_service.dart';
import '../../services/credentials_service.dart';
import '../../providers/app_state_provider.dart';
import '../../models/user.dart';
import '../../models/pilot_profile.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _saveCredentials = true;
  bool _hasSavedCredentials = false;
  bool _canCheckBiometrics = false;
  String _biometricTypeLabel = 'biometria';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkBiometricSupport();
  }

  Future<void> _loadSavedCredentials() async {
    final has = await CredentialsService.hasSavedCredentials();
    if (!mounted) return;
    String? email;
    if (has) {
      email = await CredentialsService.getSavedEmail();
    }
    if (!mounted) return;
    setState(() {
      _hasSavedCredentials = has;
      if (email != null) _emailController.text = email;
    });
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return;
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return;
      final available = await _localAuth.getAvailableBiometrics();
      String label = 'biometria';
      if (available.contains(BiometricType.face)) {
        label = 'Face ID';
      } else if (available.contains(BiometricType.fingerprint)) {
        label = 'impressão digital';
      } else if (available.isNotEmpty) {
        label = 'biometria';
      }
      if (!mounted) return;
      setState(() {
        _canCheckBiometrics = available.isNotEmpty;
        _biometricTypeLabel = label;
      });
    } catch (e) {
      // Emulador ou dispositivo sem biometria; ignorar
      if (mounted) {
        setState(() => _canCheckBiometrics = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fazer login via API
      final loginResponse = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (kDebugMode) print('🔍 Login - Resposta do login: $loginResponse');
      
      // Verificar se o login retornou o usuário diretamente
      User? user;
      if (loginResponse['user'] != null) {
        // Se o login retornou o usuário, usar ele
        user = User.fromJson(loginResponse['user']);
        if (kDebugMode) print('🔍 Login - User do login response: ${user.email}, partnerId: ${user.partnerId}');
      } else {
        // Caso contrário, buscar do endpoint /users/me
        try {
          user = await ApiService.getCurrentUser();
          if (kDebugMode) print('🔍 Login - User do getCurrentUser: ${user.email}, partnerId: ${user.partnerId}');
        } catch (e) {
          if (kDebugMode) print('⚠️ Erro ao buscar usuário: $e');
          throw Exception('Não foi possível obter dados do usuário: $e');
        }
      }
      
      // Debug: verificar dados do usuário recebido
      if (kDebugMode) print('🔍 Login - User final: ${user.email}, partnerId: ${user.partnerId}, isPartner: ${user.isPartner}, isRider: ${user.isRider}');
      
      // Salvar usuário no AppStateProvider
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.setUser(user);
      appState.completeLogin();
      // Verificar se setup já foi completado (pular Perfil do piloto e Minha garagem)
      final setupComplete = await _hasCompletedSetup(user);
      appState.setSetupCompleted(setupComplete || user.onboardingCompleted);
      final pilotType = _mapPilotProfileType(user.pilotProfile);
      if (pilotType != null) {
        appState.setPilotProfileType(pilotType);
      }
      appState.setDeliveryModerationStatus(
        user.hasVerifiedDocuments
            ? DeliveryModerationStatus.approved
            : DeliveryModerationStatus.pending,
      );
      
      // Debug: verificar após salvar
      if (kDebugMode) print('🔍 Login - User salvo no AppState: ${appState.user?.email}, partnerId: ${appState.user?.partnerId}');

      // Guardar credenciais se o utilizador marcou a opção
      try {
        await CredentialsService.saveCredentials(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          save: _saveCredentials,
        );
      } catch (_) {
        // Falha ao guardar não impede o login
        if (mounted && _saveCredentials) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login concluído, mas não foi possível guardar as credenciais.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Navegar para a home
      if (mounted) {
        widget.onLogin();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erro no login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_hasSavedCredentials) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faça login com e-mail e senha e marque "Guardar e-mail e senha" para usar biometria depois.')),
        );
      }
      return;
    }
    String? email;
    String? password;
    try {
      email = await CredentialsService.getSavedEmail();
      password = await CredentialsService.getSavedPassword();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ler as credenciais guardadas. Faça login manualmente.')),
        );
      }
      return;
    }
    if (email == null || password == null || email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciais guardadas inválidas. Faça login com e-mail e senha.')),
        );
      }
      return;
    }
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Use $_biometricTypeLabel para entrar no Giro Certo',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!authenticated) return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Canceled') || e.toString().contains('canceled')
                  ? 'Autenticação cancelada.'
                  : 'Biometria indisponível. Tente entrar com e-mail e senha.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loginResponse = await ApiService.login(email, password);
      User? user;
      if (loginResponse['user'] != null) {
        user = User.fromJson(loginResponse['user']);
      } else {
        user = await ApiService.getCurrentUser();
      }
      if (!mounted) return;
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.setUser(user);
      appState.completeLogin();
      final setupComplete = await _hasCompletedSetup(user);
      appState.setSetupCompleted(setupComplete || user.onboardingCompleted);
      final pilotType = _mapPilotProfileType(user.pilotProfile);
      if (pilotType != null) {
        appState.setPilotProfileType(pilotType);
      }
      appState.setDeliveryModerationStatus(
        user.hasVerifiedDocuments
            ? DeliveryModerationStatus.approved
            : DeliveryModerationStatus.pending,
      );
      widget.onLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao entrar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SizedBox.expand(
        child: Container(
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
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFD2D2D2),
                    ],
                  ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Entrar',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre na sua conta para continuar',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 48),
                  
                  // Campo Email
                  Text(
                    'Email',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Seu email',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.racingOrange,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Campo Senha
                  Text(
                    'Senha',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Sua senha',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.racingOrange,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outlined,
                        color: theme.iconTheme.color,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: theme.iconTheme.color,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Guardar e-mail e senha
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _saveCredentials,
                          onChanged: (v) => setState(() => _saveCredentials = v ?? true),
                          activeColor: AppColors.racingOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _saveCredentials = !_saveCredentials),
                        child: Text(
                          'Guardar e-mail e senha',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botão Entrar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.racingOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                  
                  if (_hasSavedCredentials && _canCheckBiometrics) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      icon: Icon(
                        _biometricTypeLabel.contains('Face') ? Icons.face : Icons.fingerprint,
                        size: 22,
                        color: AppColors.racingOrange,
                      ),
                      label: Text(
                        'Entrar com $_biometricTypeLabel',
                        style: const TextStyle(
                          color: AppColors.racingOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.racingOrange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Link para Registrar
                  Center(
                    child: GestureDetector(
                      onTap: widget.onRegister,
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: 'Ainda não tem conta? '),
                            TextSpan(
                              text: 'Registrar',
                              style: TextStyle(
                                color: AppColors.racingOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Verifica se o utilizador já completou o setup (Perfil do piloto + Minha garagem).
  /// Lojista e Delivery não precisam; riders (Casual/Diário/Racing) precisam ter bikes.
  Future<bool> _hasCompletedSetup(User user) async {
    if (user.partnerId != null) return true; // Lojista
    if (user.pilotProfile == 'TRABALHO') return true; // Delivery
    return ApiService.userHasBikes(); // Riders: precisa ter pelo menos uma moto
  }

  PilotProfileType? _mapPilotProfileType(String? profile) {
    if (profile == null) return null;
    final normalized = profile.toLowerCase();
    if (normalized.contains('trabalho') || normalized.contains('delivery')) {
      return PilotProfileType.delivery;
    }
    if (normalized.contains('pista') || normalized.contains('racing')) {
      return PilotProfileType.racing;
    }
    if (normalized.contains('fim') || normalized.contains('semana')) {
      return PilotProfileType.casual;
    }
    if (normalized.contains('urbano') || normalized.contains('diario')) {
      return PilotProfileType.diario;
    }
    return null;
  }
}
