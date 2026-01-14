import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class GarageIntroScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const GarageIntroScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<GarageIntroScreen> createState() => _GarageIntroScreenState();
}

class _GarageIntroScreenState extends State<GarageIntroScreen> {
  double _dragPosition = 0.0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.9;
    final buttonHeight = 70.0;
    final motoImageSize = 60.0;

    // Calcular a posição da moto baseada no drag
    final maxDrag = buttonWidth - motoImageSize - 10; // espaço para a moto deslizar
    final motoLeftPosition = 5.0 + (_dragPosition.clamp(0.0, maxDrag));
    final progress = (maxDrag > 0) ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

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
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Minha',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'Garagem!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vamos adicionar sua moto para uma experiencia completa dentro do APP',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Imagem grande da moto (apenas parte visível) — desliza com o botão
              Container(
                height: 220,
                alignment: Alignment.center,
                child: ClipRect(
                  child: SizedBox(
                    width: buttonWidth,
                    height: 220,
                    child: Stack(
                      children: [
                        Positioned(
                          left: -buttonWidth + (buttonWidth * progress),
                          top: 0,
                          bottom: 0,
                          width: buttonWidth * 2,
                          child: Image.asset(
                            'assets/images/moto-black.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Botão CONTINUAR com moto deslizante
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.1),
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
                      
                      // Moto deslizante
                      AnimatedPositioned(
                        duration: _completed 
                            ? const Duration(milliseconds: 300) 
                            : Duration.zero,
                        curve: Curves.easeOut,
                        left: motoLeftPosition,
                        top: (buttonHeight - motoImageSize) / 2,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            if (!_completed) {
                              setState(() {
                                _dragPosition += details.delta.dx;
                                _dragPosition = _dragPosition.clamp(0.0, maxDrag);
                                
                                if (_dragPosition >= maxDrag - 10) {
                                  _completed = true;
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    widget.onContinue();
                                  });
                                }
                              });
                            }
                          },
                          onHorizontalDragEnd: (details) {
                            if (!_completed && _dragPosition < maxDrag - 20) {
                              setState(() {
                                _dragPosition = 0.0;
                              });
                            }
                          },
                          child: Container(
                            width: motoImageSize,
                            height: motoImageSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.racingOrange,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/moto-black.png',
                                fit: BoxFit.cover,
                                width: motoImageSize - 4,
                                height: motoImageSize - 4,
                              ),
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
      ),
    );
  }
}
