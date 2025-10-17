
import java.util.Properties
import java.io.FileInputStream
// Load keystore properties early; fail fast if absent when building release
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.auto_tm.ynamly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    signingConfigs {
        create("release") {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException("key.properties missing. Create one with storeFile=, storePassword=, keyAlias=, keyPassword= for release builds.")
            }
            val required = listOf("storeFile","storePassword","keyAlias","keyPassword")
            val missing = required.filter { keystoreProperties[it] == null || keystoreProperties[it].toString().isBlank() }
            if (missing.isNotEmpty()) {
                throw GradleException("Missing keystore fields in key.properties: ${missing.joinToString()}")
            }
            storeFile = file(keystoreProperties["storeFile"].toString())
            storePassword = keystoreProperties["storePassword"].toString()
            keyAlias = keystoreProperties["keyAlias"].toString()
            keyPassword = keystoreProperties["keyPassword"].toString()
        }
    }
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        // Align with modern toolchain (AGP 8.3) & allow desugaring where needed
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
    

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.auto_tm.ynamly"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
         multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Temporarily disable to isolate FinalizeBundleTask NPE; re-enable after a successful clean build
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // Debug should NOT use release signing
            // Leave default debug signing; don't reference release config here.
        }
    }
}
dependencies {
    // ... existing dependencies ...
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Bundletool version pin (defensive) – remove if not needed after stable build
configurations.all {
    resolutionStrategy {
        force("com.android.tools.build:bundletool:1.15.6")
    }
}
flutter {
    source = "../.."
}
