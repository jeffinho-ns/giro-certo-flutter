package com.example.giro_certo

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * O [flutter_mapbox_navigation] embutido exige [FlutterFragmentActivity]: o SDK Mapbox
 * anexa-se ao ciclo de vida como [androidx.lifecycle.LifecycleOwner] / ViewModel store.
 * Com [io.flutter.embedding.android.FlutterActivity] costuma crashar ao abrir a vista.
 */
class MainActivity : FlutterFragmentActivity()


