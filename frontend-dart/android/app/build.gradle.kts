// android/app/build.gradle.kts 
//added by ssian, to verify if needed
import java.util.Properties

val envProps = Properties()
val envFile = rootProject.file(".env")
if (envFile.exists()) {
    envProps.load(envFile.inputStream())
}

val facebookAppId = envProps.getProperty("FACEBOOK_APP_ID")
//end


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.music_room"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.music_room"
        // minSdk = flutter.minSdkVersion
        minSdk = 21
        // targetSdk = flutter.targetSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        manifestPlaceholders["facebookAppId"] = 1038283177736047
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
    implementation("com.google.android.gms:play-services-auth:21.3.0")
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
    implementation("com.facebook.android:facebook-android-sdk:latest.release")
}
