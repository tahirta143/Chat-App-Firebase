plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase plugin
}

android {
    namespace = "com.example.chat_communication"
    compileSdk = 36 // Or flutter.compileSdkVersion if available

    defaultConfig {
        applicationId = "com.example.chat_communication"
        minSdk = flutter.minSdkVersion // Or flutter.minSdkVersion
        targetSdk = 36 // Or flutter.targetSdkVersion
        versionCode = 1 // Or flutter.versionCode
        versionName = "1.0" // Or flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
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

dependencies {
    // Firebase BOM (Kotlin DSL syntax)
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))

    // Optional: Add Firebase dependencies
//    implementation("com.google.firebase:firebase-analytics-ktx")
//    implementation("com.google.firebase:firebase-auth-ktx")
}
