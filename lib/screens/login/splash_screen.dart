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
    const initialStripeWidth = 40.0;
    
    // Calcular a largura da faixa laranja baseada na posição do slider
    final progress = (_dragPosition / (buttonWidth - slideButtonWidth)).clamp(0.0, 1.0);
    final stripeWidth = initialStripeWidth + (screenWidth - initialStripeWidth) * progress;

    return Scaffold(
      body: Container(
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
            // Faixa laranja animada
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              left: (screenWidth - stripeWidth) / 2,
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
                  const Spacer(flex: 3),
                  
                  // Imagem do motociclista (próxima ao botão)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Image.asset(
                        'assets/images/img-logi.png',
                        fit: BoxFit.contain,
                        width: screenWidth * 0.9,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                
                // Botão CONTINUAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                              ? const Duration(milliseconds: 300) 
                              : Duration.zero,
                          curve: Curves.easeOut,
                          left: _dragPosition.clamp(0.0, buttonWidth - slideButtonWidth),
                          top: 5,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              if (!_completed) {
                                setState(() {
                                  _dragPosition += details.delta.dx;
                                  _dragPosition = _dragPosition.clamp(0.0, buttonWidth - slideButtonWidth);
                                  
                                  if (_dragPosition >= buttonWidth - slideButtonWidth - 10) {
                                    _completed = true;
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      widget.onComplete();
                                    });
                                  }
                                });
                              }
                            },
                            onHorizontalDragEnd: (details) {
                              if (!_completed && _dragPosition < buttonWidth - slideButtonWidth - 20) {
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
    );
  }
}
