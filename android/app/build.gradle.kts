import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Optional release signing config. Provide an `android/key.properties` file
// (gitignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword` to
// sign release builds with a real keystore. If the file is missing, release
// builds fall back to the debug signing key (sideload only — updates won't
// install over a key change without uninstall).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "com.benjaminudoh10.balanced"
    compileSdk = flutter.compileSdkVersion
    // Align with jni (and other plugins) — use Flutter’s default NDK revision.
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.benjaminudoh10.balanced"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Balanced"
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Different applicationId so debug installs don't collide with the
            // installed release app: their data, prefs and DB are separate.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            manifestPlaceholders["appLabel"] = "Balanced (debug)"
        }
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.wear.tiles:tiles:1.4.0")
    implementation("androidx.wear.tiles:tiles-material:1.4.0")
    implementation("androidx.wear.watchface:watchface-complications-data-source:1.2.1")
    implementation("com.google.guava:guava:31.1-android") // Required for ListenableFuture in Tiles
}
