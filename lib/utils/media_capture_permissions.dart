import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Garante permissões antes de gravar ou escolher vídeo (evita crash no iOS/Android).
class MediaCapturePermissions {
  MediaCapturePermissions._();

  static Future<bool> ensureForVideoCapture(BuildContext context) async {
    final camera = await Permission.camera.request();
    if (!camera.isGranted) {
      if (context.mounted) {
        await _showDeniedDialog(
          context,
          title: 'Câmera necessária',
          message:
              'Permita o acesso à câmera nas definições do telemóvel para gravar momentos.',
        );
      }
      return false;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (context.mounted) {
        await _showDeniedDialog(
          context,
          title: 'Microfone necessário',
          message:
              'Para gravar vídeo com áudio, permita o acesso ao microfone nas definições.',
        );
      }
      return false;
    }
    return true;
  }

  static Future<bool> ensureForGallery(BuildContext context) async {
    Permission permission;
    if (Platform.isAndroid) {
      permission = Permission.videos;
      final videos = await permission.request();
      if (videos.isGranted || videos.isLimited) return true;
      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;
    } else {
      permission = Permission.photos;
      final photos = await permission.request();
      if (photos.isGranted || photos.isLimited) return true;
    }

    if (context.mounted) {
      await _showDeniedDialog(
        context,
        title: 'Galeria necessária',
        message:
            'Permita o acesso à galeria nas definições para escolher um vídeo.',
      );
    }
    return false;
  }

  static Future<void> _showDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Abrir definições'),
          ),
        ],
      ),
    );
  }
}
