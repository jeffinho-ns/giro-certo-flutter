plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lê GOOGLE_MAPS_API_KEY sem java.util.Properties (evita "Unresolved reference: util" no Kotlin DSL).
/** Token público Mapbox (pk.) — também em `android/.../mapbox_access_token.xml` se preferir ficheiro. */
val mapboxAccessToken = run {
    val f = rootProject.file("local.properties")
    if (!f.exists()) return@run ""
    f.readLines().mapNotNull { line ->
        val trimmed = line.trim()
        if (trimmed.startsWith("MAPBOX_ACCESS_TOKEN=")) {
            trimmed.substringAfter("=", "").trim().trim('"')
        } else {
            null
        }
    }.firstOrNull()
}?.takeIf { it.isNotEmpty() } ?: (System.getenv("MAPBOX_ACCESS_TOKEN") ?: "")

val googleMapsApiKey = run {
    val f = rootProject.file("local.properties")
    if (!f.exists()) return@run ""
    f.readLines().mapNotNull { line ->
        val trimmed = line.trim()
        if (trimmed.startsWith("GOOGLE_MAPS_API_KEY=")) {
            trimmed.substringAfter("=", "").trim().trim('"')
        } else {
            null
        }
    }.firstOrNull()
}?.takeIf { it.isNotEmpty() } ?: (System.getenv("GOOGLE_MAPS_API_KEY") ?: "")

android {
    namespace = "com.example.giro_certo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.giro_certo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
        resValue(
            "string",
            "mapbox_access_token",
            mapboxAccessToken.ifEmpty {
                "CONFIGURE_MAPBOX_ACCESS_TOKEN_NO_LOCAL_PROPERTIES"
            },
        )
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}