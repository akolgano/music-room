# music-room

This branch is for the frontend portion, i will be running program on physical android connected via USB.

## Getting Started with Kotlin Android Development on Terminal

## 1. Install Java Development Kit (JDK)

```bash
sudo apt update
sudo apt install openjdk-17-jdk
java -version
javac -version
```

## 2. Install Android SDK Command Line Tools

```bash
mkdir -p ~/Android/Sdk
cd ~/Android/Sdk
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-*_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/
rmdir cmdline-tools/latest/cmdline-tools
```

## 3. Set up Environment Variables

Add these to `~/.zshrc` file:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
```

Then refresh your environment:

```bash
source ~/.zshrc
```

## 4. Install Required Android SDK Components

```bash
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2" "extras;android;m2repository" "extras;google;m2repository"
```

## 5. Install Kotlin Compiler

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install kotlin
sdk install gradle
gradle --version
```

## 6. Create a New Android Project

```bash
mkdir -p ~/projects/music-room-frontend
cd ~/projects/music-room-frontend
sudo apt install gradle
gradle init --type kotlin-application --dsl kotlin
```

## 7. Configure the Android Project

Create a `settings.gradle.kts` file:

```kotlin
rootProject.name = "MyKotlinApp"
```

Create a `build.gradle.kts` file with Android configuration:

```kotlin
plugins {
    id("com.android.application") version "7.4.2"
    kotlin("android") version "1.8.10"
}

android {
    compileSdk = 33
    
    defaultConfig {
        applicationId = "com.example.mykotlinapp"
        minSdk = 23
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }
    
    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.10.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
```

## 8. Set up project structure

```bash
mkdir -p app/src/main/java/com/example/mykotlinapp
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
```

## 9. Build and install the app

```bash
./gradlew build
./gradlew installDebug
```

## 10. Helpful Tools

```bash
sudo apt install adb
adb devices
adb install app/build/outputs/apk/debug/app-debug.apk
adb logcat
```
