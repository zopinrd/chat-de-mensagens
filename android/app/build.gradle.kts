plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    
    namespace = "com.example.app_chat"
    compileSdk = 35 // Defina explicitamente a versão desejada

    ndkVersion = "27.0.12077973" // Versão que o Flutter Secure Storage está pedindo

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.app_chat"
        minSdk = 23 // Corrigido para suportar flutter_secure_storage
        targetSdk = 35 // Defina explicitamente
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
