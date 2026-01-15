import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motorcycle_data_service.dart';

class AppPreloadService {
  static bool _isPreloaded = false;

  static Future<void> preloadAllAssets(BuildContext context) async {
    if (_isPreloaded) return;

    try {
      // Pré-carregar todas as imagens principais
      final imagesToPreload = [
        'assets/images/img-logi.png',
        'assets/images/moto-black.png',
        'assets/marca/banner-header.png',
        'assets/marca/honda.png',
        'assets/marca/yamaha.png',
        'assets/marca/kawasaki.png',
        'assets/marca/royal.png',
        'assets/marca/bajaj.png',
        'assets/marca/bmw.png',
        'assets/marca/harley.png',
        'assets/marca/dicati.png',
        'assets/marca/tvs.png',
        'assets/marca/suzuki.png',
        'assets/marca/ktm.png',
        'assets/marca/shineray.png',
        'assets/marca/mottu.png',
        'assets/marca/avelloz.png',
        'assets/marca/baja.png',
        'assets/marca/triumph.png',
        'assets/marca/dafra.png',
        'assets/marca/voltz.png',
        'assets/marca/aurat.png',
        'assets/marca/gcx.png',
        'assets/marca/kymco.png',
        'assets/marca/piaggio.png',
      ];

      // Pré-carregar imagens em paralelo com timeout
      await Future.wait(
        imagesToPreload.map((imagePath) async {
          try {
            await precacheImage(AssetImage(imagePath), context).timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                // Timeout silencioso - continua o fluxo
              },
            );
          } catch (e) {
            // Ignora erros de imagens não encontradas
          }
        }),
        eagerError: false,
      );

      // Pré-computar lista de motos (já faz cache internamente)
      MotorcycleDataService.getAllMotorcycles();

      _isPreloaded = true;
    } catch (e) {
      // Continua mesmo se houver erro no pré-carregamento
      _isPreloaded = true; // Marca como pré-carregado mesmo com erro
    }
  }

  static bool get isPreloaded => _isPreloaded;
}
