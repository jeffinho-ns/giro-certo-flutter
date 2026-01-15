import 'package:flutter/material.dart';
import '../../utils/colors.dart';

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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      widget.onLogin();
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
                  
                  const SizedBox(height: 48),
                  
                  // Botão Entrar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
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
                      child: const Text('Entrar'),
                    ),
                  ),
                  
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
}
