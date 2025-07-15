// android/app/build.gradle.kts 
import java.util.Properties

val envProps = Properties()
val envFile = rootProject.file(".env")
if (envFile.exists()) {
    envProps.load(envFile.inputStream())
}

val facebookAppId = envProps.getProperty("FACEBOOK_APP_ID")



plugins {

    id("com.android.application")
    id("com.google.gms.google-services")

    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")

}

android {
    namespace = "com.example.music_room"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.music_room"
        // minSdk = flutter.minSdkVersion
        minSdk = 23
        // targetSdk = flutter.targetSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
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
    implementation("com.facebook.android:facebook-android-sdk:latest.release")

    // Import the BoM for the Firebase platform
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))

    // Add the dependency for the Firebase Authentication library
    implementation("com.google.firebase:firebase-auth")
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")

}

apply(plugin = "com.google.gms.google-services")