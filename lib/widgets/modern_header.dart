import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/app_state_provider.dart';
import '../providers/drawer_provider.dart';
import 'api_image.dart';

class ModernHeader extends StatefulWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  /// Se true, usa layout compacto para sobrepor o mapa (sem fundo sólido).
  final bool transparentOverMap;

  /// Se true, esconde o clock e KM da moto no header.
  final bool hideClockAndKm;

  const ModernHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.transparentOverMap = false,
    this.hideClockAndKm = false,
  });

  @override
  State<ModernHeader> createState() => _ModernHeaderState();
}

class _ModernHeaderState extends State<ModernHeader> {
  late Timer _clockTimer;
  String _timeStr = '';
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  DateTime? _lastPositionTimestamp;
  double? _currentSpeedKmh;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    if (!widget.hideClockAndKm) {
      _startSpeedTracking();
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    final str =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (str != _timeStr && mounted) {
      setState(() => _timeStr = str);
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startSpeedTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        ),
      ).listen(_onPositionUpdate);
    } catch (_) {
      // Mantem fallback visual (-- km/h) se GPS falhar.
    }
  }

  void _onPositionUpdate(Position pos) {
    final now = DateTime.now();
    var speedMps = pos.speed >= 0 ? pos.speed : 0.0;

    if (speedMps <= 0 &&
        _lastPosition != null &&
        _lastPositionTimestamp != null) {
      final dt = now.difference(_lastPositionTimestamp!).inMilliseconds / 1000.0;
      if (dt > 0.5) {
        final meters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        speedMps = meters / dt;
      }
    }

    // Ignora picos irreais de GPS para evitar leituras absurdas.
    final nextKmh = speedMps * 3.6;
    if (nextKmh.isNaN || nextKmh.isInfinite || nextKmh > 180) {
      _lastPosition = pos;
      _lastPositionTimestamp = now;
      return;
    }

    final smoothed = _currentSpeedKmh == null
        ? nextKmh
        : (_currentSpeedKmh! * 0.65) + (nextKmh * 0.35);

    if (mounted) {
      setState(() => _currentSpeedKmh = smoothed);
    }

    _lastPosition = pos;
    _lastPositionTimestamp = now;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final drawerProvider = Provider.of<DrawerProvider>(context, listen: false);
    final user = appState.user;
    final theme = Theme.of(context);

    final speedStr = _currentSpeedKmh == null
        ? '-- km/h'
        : '${_currentSpeedKmh!.toStringAsFixed(1).replaceAll('.', ',')} km/h';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: widget.transparentOverMap
            ? Colors.transparent
            : theme.scaffoldBackgroundColor,
        boxShadow: widget.transparentOverMap
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                // Foto e saudação ao piloto (esquerda)
                GestureDetector(
                  onTap: () => drawerProvider.openProfileDrawer(),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                            ? ClipOval(
                                child: ApiImage(
                                  url: user.photoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${user?.name.split(' ').first ?? 'Piloto'} 👋',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            user?.pilotProfile ?? 'Piloto',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Display [Hora] | [Velocidade em tempo real] (direita)
                if (!widget.hideClockAndKm)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timeStr,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 1,
                            height: 14,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        Icon(
                          LucideIcons.gauge,
                          size: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          speedStr,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (widget.title.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (widget.showBackButton)
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: widget.onBackPressed ??
                          () => Navigator.of(context).pop(),
                      color: theme.iconTheme.color,
                    ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
