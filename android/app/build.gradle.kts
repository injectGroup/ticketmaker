import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload-key credentials are machine-local and git-ignored; see docs/development.md.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

// Play rejects debug-signed uploads, so fail the build rather than quietly
// producing an artifact that cannot be released.
val releaseArtifactRequested: Boolean =
    gradle.startParameter.taskNames.any { taskName: String ->
        taskName.contains("Release") &&
            (taskName.contains("bundle") ||
                taskName.contains("assemble") ||
                taskName.contains("package"))
    }
if (releaseArtifactRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Missing android/key.properties. Add storeFile, storePassword, " +
            "keyAlias and keyPassword for the upload keystore before " +
            "building a release artifact.",
    )
}

android {
    namespace = "com.agathakakalogical.quickticketmaker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.agathakakalogical.quickticketmaker"
        minSdk = flutter.minSdkVersion
        // Follow the toolchain: Play raises its required target API annually.
        targetSdk = flutter.targetSdkVersion
        // Single source of truth is pubspec.yaml's `version:` field.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
