
import java.util.Properties
import java.io.FileInputStream
val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
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
            val hasSigning = listOf("keyAlias","keyPassword","storeFile","storePassword").all { keystoreProperties[it] != null }
            if (hasSigning) {
                create("release") {
                    val alias = keystoreProperties["keyAlias"]?.toString()
                    val keyPass = keystoreProperties["keyPassword"]?.toString()
                    val storePath = keystoreProperties["storeFile"]?.toString()
                    val storePass = keystoreProperties["storePassword"]?.toString()

                    if (alias.isNullOrBlank() || keyPass.isNullOrBlank() || storePath.isNullOrBlank() || storePass.isNullOrBlank()) {
                        throw GradleException("Incomplete keystore configuration in key.properties. Expected keyAlias, keyPassword, storeFile, storePassword.")
                    }
                    keyAlias = alias
                    keyPassword = keyPass
                    storeFile = file(storePath)
                    storePassword = storePass
                }
            } else {
                // Provide a placeholder debug-like signing config for release if keystore absent to avoid null cast crash.
                create("release") {
                    println("[WARN] key.properties missing or incomplete. Using debug signing for release build. Provide key.properties to sign production builds.")
                    // Intentionally left blank – Gradle will inject debug keys later if needed.
                }
            }
    }
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
       
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
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
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
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
    // ... other dependencies
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // <-- Add this line
}
flutter {
    source = "../.."
}
