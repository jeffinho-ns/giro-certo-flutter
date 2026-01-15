import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _dragPosition = 0.0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.9;
    const slideButtonWidth = 60.0;

    // Calcular o progresso baseado na posição do slider
    final maxDrag = buttonWidth - slideButtonWidth;
    double progress =
        maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

    // Se completou, garantir que o progress seja exatamente 1.0 para cobrir toda a tela
    if (_completed) {
      progress = 1.0;
    }

    // Calcular a largura da faixa laranja - expande do centro para os lados
    // Quando progress = 0: width = 0, left = screenWidth/2 (centro, invisível)
    // Quando progress = 1: width = screenWidth, left = 0 (cobre toda a tela)
    final stripeWidth = screenWidth * progress;
    final stripeLeft =
        (screenWidth - stripeWidth) / 2; // Centraliza e expande para os lados

    // Calcular opacidade da logo - começa em 40% e vai até 100%
    final logoOpacity = 0.4 + (0.6 * progress);

    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF), // #ffffff
                Color(0xFFD2D2D2), // #d2d2d2
              ],
            ),
          ),
          child: Stack(
            children: [
              // Faixa laranja animada - expande do meio para os lados
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                left: stripeLeft,
                top: 0,
                bottom: 0,
                width: stripeWidth,
                child: Container(
                  color: AppColors.racingOrange,
                ),
              ),

              // Conteúdo principal
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Logo com opacidade animada (maior e mais para cima)
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 100),
                          opacity: logoOpacity,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            width: screenWidth * 0.85,
                          ),
                        ),
                      ),
                    ),

                    // Imagem do motociclista (maior, próxima ao botão)
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Image.asset(
                          'assets/images/img-logi.png',
                          fit: BoxFit.contain,
                          width: screenWidth * 1.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botão CONTINUAR
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      child: Container(
                        width: buttonWidth,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Texto CONTINUAR
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 80),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'CONTINUAR',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black54,
                                      size: 20,
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black54,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Slider com anel branco
                            AnimatedPositioned(
                              duration: _completed
                                  ? const Duration(milliseconds: 80)
                                  : Duration.zero,
                              curve: Curves.easeOut,
                              left: _dragPosition.clamp(
                                  0.0, buttonWidth - slideButtonWidth),
                              top: 5,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  if (!_completed) {
                                    setState(() {
                                      _dragPosition += details.delta.dx;
                                      _dragPosition = _dragPosition.clamp(
                                          0.0, buttonWidth - slideButtonWidth);

                                      if (_dragPosition >=
                                          buttonWidth - slideButtonWidth - 10) {
                                        _completed = true;
                                        // Small delay to allow final render, then navigate instantly
                                        Future.microtask(
                                            () => widget.onComplete());
                                      }
                                    });
                                  }
                                },
                                onHorizontalDragEnd: (details) {
                                  if (!_completed &&
                                      _dragPosition <
                                          buttonWidth - slideButtonWidth - 20) {
                                    setState(() {
                                      _dragPosition = 0.0;
                                    });
                                  }
                                },
                                child: Container(
                                  width: slideButtonWidth,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Anel branco externo
                                      Container(
                                        width: slideButtonWidth,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      // Círculo laranja interno
                                      Container(
                                        width: slideButtonWidth - 12,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.racingOrange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward,
                                          color: AppColors.textPrimary,
                                          size: 24,
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
