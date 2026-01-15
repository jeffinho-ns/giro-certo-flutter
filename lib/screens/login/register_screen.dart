import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class RegisterScreen extends StatefulWidget {
  final Function(String name, String email, String password, int age) onRegister;

  const RegisterScreen({
    super.key,
    required this.onRegister,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      widget.onRegister(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        int.parse(_ageController.text),
      );
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
                    'Registrar',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie sua conta para começar',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 48),
                  
                  // Campo Nome
                  Text(
                    'Nome Completo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Seu nome completo',
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
                        Icons.person_outlined,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu nome';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Campo Idade
                  Text(
                    'Idade',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Sua idade',
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
                        Icons.cake,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua idade';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 16 || age > 100) {
                        return 'Idade inválida';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  
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
                      if (value.length < 6) {
                        return 'Senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Botão Registrar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleRegister,
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
                      child: const Text('Registrar'),
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
