import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Som e vibração contínuos enquanto a oferta imersiva estiver visível.
class DeliveryOfferAlertFeedback {
  Timer? _pulseTimer;
  bool _active = false;

  Future<void> start() async {
    if (_active) return;
    _active = true;
    await _pulse();
    _pulseTimer = Timer.periodic(
      const Duration(milliseconds: 850),
      (_) => unawaited(_pulse()),
    );
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    _pulseTimer?.cancel();
    _pulseTimer = null;
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.cancel();
      }
    } catch (e) {
      debugPrint('DeliveryOfferAlertFeedback cancel: $e');
    }
  }

  Future<void> _pulse() async {
    if (!_active) return;
    unawaited(SystemSound.play(SystemSoundType.alert));
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        final hasAmplitude = await Vibration.hasAmplitudeControl();
        if (hasAmplitude == true) {
          await Vibration.vibrate(
            duration: 520,
            amplitude: 255,
          );
        } else {
          await Vibration.vibrate(duration: 520);
        }
        return;
      }
    } catch (e) {
      debugPrint('DeliveryOfferAlertFeedback vibrate: $e');
    }
    await HapticFeedback.heavyImpact();
  }
}
