import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SlideButton extends StatefulWidget {
  final VoidCallback onComplete;
  final String text;

  const SlideButton({
    super.key,
    required this.onComplete,
    this.text = 'Desliza para Iniciar',
  });

  @override
  State<SlideButton> createState() => _SlideButtonState();
}

class _SlideButtonState extends State<SlideButton> {
  double _dragPosition = 0.0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.8;
    const slideButtonWidth = 80.0;

    return Container(
      width: buttonWidth,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.mediumGray,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              widget.text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedPositioned(
            duration: _completed ? const Duration(milliseconds: 300) : Duration.zero,
            curve: Curves.easeOut,
            left: _dragPosition.clamp(0.0, buttonWidth - slideButtonWidth),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (!_completed) {
                  setState(() {
                    _dragPosition += details.delta.dx;
                    _dragPosition = _dragPosition.clamp(0.0, buttonWidth - slideButtonWidth);
                    
                    if (_dragPosition >= buttonWidth - slideButtonWidth - 10) {
                      _completed = true;
                      widget.onComplete();
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
                  color: AppColors.racingOrange,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.racingOrange.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
