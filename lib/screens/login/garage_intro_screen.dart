import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../providers/theme_provider.dart';

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
    // ignore: unused_local_variable
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonWidth = screenWidth * 0.9;
    const buttonHeight = 75.0;
    const circleSize = 55.0;

    final maxDrag = buttonWidth - circleSize - 16;
    final progress =
        maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;
    final circleLeftPosition = 8.0 + (_dragPosition.clamp(0.0, maxDrag));

    // --- LÓGICA DA IMAGEM CORRIGIDA ---

    // 1. Zoom (Largura da imagem)
    final imageWidth = screenWidth * 3.2;

    // 2. Cálculo do deslocamento
    // Queremos começar vendo a FRENTE (Lado Direito da imagem).
    // Para isso, precisamos empurrar a imagem toda para a esquerda.
    // O valor exato para alinhar à direita seria: -(imageWidth - screenWidth).
    final startOffset = -(imageWidth - screenWidth);

    // Queremos terminar vendo a TRASEIRA (Lado Esquerdo da imagem).
    // Para isso, o offset deve chegar perto de 0.
    // Vamos deixar um pequeno ajuste (-50) para não colar totalmente na borda esquerda se não quiser.
    const endOffset = 0.0;

    // Interpolação linear entre o início e o fim baseada no progresso do botão
    // Quando progress é 0, estamos em startOffset (Vemos a frente)
    // Quando progress é 1, estamos em endOffset (Vemos a traseira)
    // O movimento será da esquerda para direita (valor negativo indo para zero)
    final currentOffset = startOffset + (progress * (endOffset - startOffset));

    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minha',
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 0.9,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Text(
                    'Garagem!',
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: theme.textTheme.displayLarge?.color ??
                          AppColors.lightTextPrimary,
                      height: 0.9,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Vamos adicionar sua\nmoto para uma\nexperiencia completa\ndentro do APP',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.displayLarge?.color ??
                          AppColors.lightTextPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Área da Imagem
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    child: Transform.translate(
                      offset: Offset(currentOffset, 0),
                      child: Container(
                        width: imageWidth,
                        // Alinhamento à esquerda garante que o offset 0 seja o início da imagem
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/moto-black.png',
                          fit: BoxFit.cover, // Garante altura total e zoom
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Botão Deslizante
            Center(
              child: Container(
                width: buttonWidth,
                height: buttonHeight,
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(left: circleSize / 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CONTINUAR',
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color ??
                                    AppColors.lightTextPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right,
                                color: (theme.textTheme.bodyLarge?.color ??
                                        AppColors.lightTextPrimary)
                                    .withOpacity(0.5),
                                size: 24),
                            Icon(Icons.chevron_right,
                                color: (theme.textTheme.bodyLarge?.color ??
                                        AppColors.lightTextPrimary)
                                    .withOpacity(0.3),
                                size: 24),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: circleLeftPosition,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          if (!_completed) {
                            setState(() {
                              _dragPosition += details.delta.dx;
                              _dragPosition = _dragPosition.clamp(0.0, maxDrag);

                              if (_dragPosition >= maxDrag - 5) {
                                _completed = true;
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
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
                          } else if (!_completed &&
                              _dragPosition >= maxDrag - 20) {
                            setState(() {
                              _dragPosition = maxDrag;
                              _completed = true;
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                widget.onContinue();
                              });
                            });
                          }
                        },
                        child: Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeProvider.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
