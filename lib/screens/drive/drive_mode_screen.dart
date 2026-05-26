import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/colors.dart';

/// Tela "Modo Drive" — interface minimalista para usar enquanto pilota.
/// Mostra hora, velocidade atual (GPS) e km da moto em letras grandes.
/// Mantém a tela acesa e suprime distrações.
class DriveModeScreen extends StatefulWidget {
  const DriveModeScreen({super.key});

  @override
  State<DriveModeScreen> createState() => _DriveModeScreenState();
}

class _DriveModeScreenState extends State<DriveModeScreen> {
  Timer? _clockTimer;
  StreamSubscription<Position>? _positionSub;
  String _timeStr = '';
  double _speedKmh = 0;
  double _distanceKm = 0;
  Position? _lastPos;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    _updateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );
    _startGps();
  }

  Future<void> _startGps() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen(_onPos);
    } catch (_) {
      // permanece em --
    }
  }

  void _onPos(Position pos) {
    final speed = pos.speed >= 0 ? pos.speed * 3.6 : 0;
    if (_lastPos != null) {
      final d = Geolocator.distanceBetween(
            _lastPos!.latitude,
            _lastPos!.longitude,
            pos.latitude,
            pos.longitude,
          ) /
          1000.0;
      _distanceKm += d;
    }
    _lastPos = pos;
    if (mounted) {
      setState(() => _speedKmh = speed.toDouble());
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    final s =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (s != _timeStr && mounted) {
      setState(() => _timeStr = s);
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _positionSub?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.12),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(LucideIcons.arrowLeft,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(LucideIcons.car,
                            color: AppColors.racingOrange, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Modo Drive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _speedKmh.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 200,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: AppColors.racingOrangeLight,
                        letterSpacing: -8,
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _stat(
                      icon: LucideIcons.gauge,
                      label: 'Distância',
                      value: '${_distanceKm.toStringAsFixed(2)} km',
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _stat(
                      icon: LucideIcons.bike,
                      label: 'Hodômetro',
                      value: bike != null
                          ? '${(bike.currentKm + _distanceKm).toStringAsFixed(0)} km'
                          : '—',
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _stat(
                      icon: LucideIcons.flame,
                      label: 'Modo',
                      value: 'Foco',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.racingOrange, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        color: Colors.white.withOpacity(0.15),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}
