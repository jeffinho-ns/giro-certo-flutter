import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Seta estilo navegação (similar ao ícone de direção do Google Maps).
/// Para usar uma **moto 3D** como na captura do Google Maps, substitua por um PNG
/// em `assets/` e carregue com `BitmapDescriptor.fromAssetImage(...)`.
class NavigationRiderMarker {
  NavigationRiderMarker._();

  static BitmapDescriptor? _cached;
  static int _cachedAtRevision = -1;
  /// Incremente ao alterar tamanho/forma para invalidar o cache em runtime.
  static const int _revision = 2;

  static Future<BitmapDescriptor> bitmap() async {
    if (_cached != null && _cachedAtRevision == _revision) return _cached!;
    _cached = await _drawChevron();
    _cachedAtRevision = _revision;
    return _cached!;
  }

  static Future<BitmapDescriptor> _drawChevron() async {
    const double size = 72;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    final body = Path()
      ..moveTo(center.dx, size * 0.14)
      ..lineTo(size * 0.86, size * 0.86)
      ..lineTo(center.dx, size * 0.58)
      ..lineTo(size * 0.14, size * 0.86)
      ..close();

    canvas.save();
    canvas.translate(0, 2);
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(body, shadowPaint);
    canvas.restore();

    final fillPaint = Paint()
      ..color = const Color(0xFF1A73E8)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.055;

    canvas.drawPath(body, fillPaint);
    canvas.drawPath(body, strokePaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    return BitmapDescriptor.bytes(
      bd.buffer.asUint8List(),
      width: 28,
      height: 28,
      imagePixelRatio: 2,
    );
  }
}
