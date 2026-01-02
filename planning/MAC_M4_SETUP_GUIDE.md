# SZ Pic - Mac M4 Setup Guide for Android Studio

## Overview
This guide is specifically tailored for developing the SZ Pic app on a Mac M4 (Apple Silicon) using Android Studio.

## Prerequisites for Mac M4

### 1. Install Homebrew (if not already installed)
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 2. Install Flutter via Homebrew (Recommended for M4 Mac)
```bash
# Install Flutter
brew install flutter

# Verify installation
flutter --version

# Check for issues
flutter doctor
```

Alternative: Manual Installation
```bash
# Download Flutter for Apple Silicon
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH in ~/.zshrc
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify
flutter --version
```

### 3. Install and Configure Android Studio

**Download Android Studio for Apple Silicon:**
- Visit https://developer.android.com/studio
- Download "Android Studio Jellyfish | 2024.1.1" or later with Apple Silicon support
- Install to Applications folder

**Configure Android Studio:**
```bash
# Open Android Studio
open /Applications/Android\ Studio.app

# Through Android Studio:
# 1. Go to Preferences → Appearance & Behavior → System Settings → Android SDK
# 2. Install SDK Platform-Tools, Build-Tools
# 3. Install Android SDK 34 (or latest)
```

### 4. Install Flutter and Dart Plugins in Android Studio

1. Open Android Studio
2. Go to **Settings** (⌘,) → **Plugins**
3. Search for "Flutter" and install
4. This will automatically install the Dart plugin
5. Restart Android Studio

### 5. Accept Android Licenses
```bash
flutter doctor --android-licenses
# Press 'y' to accept all licenses
```

### 6. Install Rosetta 2 (for compatibility)
```bash
# Some Android build tools may still need Rosetta
sudo softwareupdate --install-rosetta
```

### 7. Install CocoaPods (for future iOS development)
```bash
# Install Ruby version manager (if needed)
brew install rbenv ruby-build

# Install recent Ruby
rbenv install 3.2.0
rbenv global 3.2.0

# Install CocoaPods
gem install cocoapods

# Or via Homebrew
brew install cocoapods
```

### 8. Verify Flutter Setup
```bash
flutter doctor -v
```

Expected output should show:
```
[✓] Flutter (Channel stable, 3.x.x, on macOS 14.x darwin-arm64)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS
[✓] Chrome - develop for the web
[✓] Android Studio (version 2024.1)
[✓] VS Code (version 1.x.x)
[✓] Connected device (1 available)
```

## Project Setup for Mac M4

### Option 1: Create New Flutter Project in Android Studio

1. **Open Android Studio**
2. **New Flutter Project**:
   - File → New → New Flutter Project
   - Select "Flutter Application"
   - Project name: `sz_pic`
   - Organization: `com.szpic`
   - Android language: Kotlin
   - iOS language: Swift
   - Platforms: Android, iOS, Web
   - Click "Create"

3. **Location**: `/Users/sz/StudioProjects/sz_pic_flutter`

### Option 2: Create via Command Line

```bash
# Navigate to StudioProjects
cd /Users/sz/StudioProjects

# Create Flutter project
flutter create --org com.szpic --project-name sz_pic sz_pic_flutter

# Open in Android Studio
open -a "Android Studio" sz_pic_flutter
```

### Configure for Mac M4 Performance

**android/gradle.properties** (add these for M4 optimization):
```properties
org.gradle.jvmargs=-Xmx4096M -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.daemon=true
org.gradle.configureondemand=true

# Enable AndroidX
android.useAndroidX=true
android.enableJetifier=true
```

**android/app/build.gradle** (optimized):
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        applicationId "com.szpic.sz_pic"
        minSdk 24  // Android 7.0+
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
        
        // M4 optimization
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }
    
    buildTypes {
        release {
            // Optimizations for release build
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Signing configuration (to be added later)
        }
        
        debug {
            // Fast builds for development
            shrinkResources false
            minifyEnabled false
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = '17'
    }
}
```

## Android Emulator Setup for M4 Mac

### Create ARM64 Emulator (Best Performance on M4)

1. **Open AVD Manager** in Android Studio
2. **Create Virtual Device**:
   - Device: Pixel 8 or Pixel 8 Pro
   - System Image: **Android 14 (API 34)** with **Google APIs**
   - **Important**: Select **arm64-v8a** architecture (not x86_64)
3. **Configure**:
   - RAM: 4096 MB
   - VM Heap: 512 MB
   - Internal Storage: 8192 MB
   - Enable "Hardware - GLES 2.0" for better graphics
4. **Click Finish**

### Command Line Alternative:
```bash
# List available system images
sdkmanager --list | grep system-images

# Download ARM64 image for Android 14
sdkmanager "system-images;android-34;google_apis;arm64-v8a"

# Create emulator
avdmanager create avd -n "Pixel_8_ARM64" \
  -k "system-images;android-34;google_apis;arm64-v8a" \
  -d "pixel_8"
```

### Use Physical Device (Recommended for Better Performance)

1. **Enable Developer Options** on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings → Developer Options
   - Enable "USB Debugging"

2. **Connect via USB**:
   ```bash
   # List connected devices
   flutter devices
   
   # Or
   adb devices
   ```

3. **Wireless Debugging** (Android 11+):
   ```bash
   # Enable wireless debugging on device
   # Settings → Developer Options → Wireless Debugging
   
   # Pair device (one time)
   adb pair <IP>:<PORT>
   
   # Connect
   adb connect <IP>:<PORT>
   
   # Verify
   flutter devices
   ```

## Running the App on Mac M4

### Using Android Studio

1. **Select Device/Emulator** from dropdown (top toolbar)
2. **Click Run** (▶️ button) or press **Ctrl+R**
3. **Hot Reload**: Click ⚡ or press **Ctrl+\**
4. **Hot Restart**: Click 🔄 or press **Ctrl+Shift+\**

### Using Terminal

```bash
# Navigate to project
cd /Users/sz/StudioProjects/sz_pic_flutter

# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on Android device/emulator
flutter run -d android

# Run with verbose logging
flutter run -v

# Run in release mode (faster, smaller)
flutter run --release

# Profile mode (for performance testing)
flutter run --profile
```

### Keyboard Shortcuts While Running
- **r**: Hot reload
- **R**: Hot restart
- **p**: Toggle performance overlay
- **o**: Toggle platform (Android/iOS)
- **q**: Quit

## Installing Ollama on Mac M4

### Install Ollama (for local AI)
```bash
# Download and install from https://ollama.ai
# Or via Homebrew
brew install ollama

# Start Ollama service
ollama serve

# In another terminal, test models
ollama pull llava  # Vision model for image analysis
ollama pull mistral  # General model

# Verify
ollama list

# Test
ollama run llava "Describe this image" --image path/to/image.jpg
```

### Configure Ollama for Network Access
```bash
# Default runs on localhost:11434
# To allow Flutter app to connect:
curl http://localhost:11434/api/tags

# If using emulator, use special IP:
# Emulator can reach host at: 10.0.2.2:11434
```

## Building the App

### Debug Build (Testing)
```bash
# Build APK
flutter build apk --debug

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release Build (Distribution)
```bash
# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Split APKs by architecture (smaller downloads)
flutter build apk --split-per-abi --release
```

### Install APK on Device
```bash
# Using Flutter
flutter install

# Using ADB
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Performance Optimization for M4 Mac

### 1. Speed Up Gradle Builds
**~/.gradle/gradle.properties**:
```properties
org.gradle.jvmargs=-Xmx8192m -XX:MaxMetaspaceSize=2048m
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.daemon=true
kotlin.incremental=true
kotlin.caching.enabled=true
```

### 2. Enable Flutter Build Cache
```bash
# Enable build cache
flutter config --enable-local-engine-src-path=false

# Clear cache if needed
flutter clean
flutter pub get
```

### 3. Optimize Android Studio Settings
1. **Preferences → Build, Execution, Deployment → Compiler**:
   - Set "Compiler Process heap size" to 4096 MB
   - Enable "Compile independent modules in parallel"
2. **Preferences → Appearance & Behavior → System Settings**:
   - Increase max file size: 10 MB
   - Enable "Reopen projects on startup"

### 4. Use Flutter DevTools for Profiling
```bash
# Install DevTools
flutter pub global activate devtools

# Run DevTools
flutter pub global run devtools

# Or
dart devtools

# Run app with DevTools
flutter run --devtools
```

## Troubleshooting Mac M4 Specific Issues

### Issue: Gradle Daemon Not Starting
```bash
# Kill existing Gradle daemons
cd android
./gradlew --stop

# Clean and rebuild
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Issue: CocoaPods Issues (for iOS)
```bash
cd ios
rm -rf Pods Podfile.lock
pod deintegrate
pod install
cd ..
flutter run
```

### Issue: Flutter Doctor Shows Xcode Issues
```bash
# Install Xcode Command Line Tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Accept licenses
sudo xcodebuild -license accept
```

### Issue: Slow Build Times
```bash
# Ensure using ARM64 toolchain
file $(which flutter)
# Should show: Mach-O 64-bit executable arm64

# Update Flutter
flutter upgrade

# Clear build artifacts
flutter clean
rm -rf ~/.pub-cache
flutter pub get
```

### Issue: Emulator Not Starting
```bash
# Check virtualization
sysctl kern.hv_support
# Should return: kern.hv_support: 1

# List emulators
emulator -list-avds

# Start emulator from command line
emulator -avd Pixel_8_ARM64

# Check logs
flutter doctor -v
```

## Recommended Android Studio Plugins for M4

1. **Flutter** (essential)
2. **Dart** (installed with Flutter)
3. **Flutter Intl** (localization)
4. **Flutter Redux Snippets** (if using Redux)
5. **Rainbow Brackets** (code readability)
6. **GitToolBox** (Git integration)
7. **Key Promoter X** (learn shortcuts)

## Git Setup (Recommended)

```bash
# Initialize Git repository
cd /Users/sz/StudioProjects/sz_pic_flutter
git init

# Create .gitignore (Flutter project already has one)
# Add additional rules if needed:
echo ".DS_Store" >> .gitignore
echo ".idea/" >> .gitignore

# Initial commit
git add .
git commit -m "Initial commit: Flutter project setup"

# Link to remote (optional)
git remote add origin <your-repo-url>
git push -u origin main
```

## Development Workflow on Mac M4

### Daily Development
```bash
# 1. Open project in Android Studio
open -a "Android Studio" /Users/sz/StudioProjects/sz_pic_flutter

# 2. Start Ollama (in Terminal)
ollama serve &

# 3. Start emulator or connect device
flutter devices

# 4. Run app (in Android Studio or Terminal)
flutter run

# 5. Make changes, hot reload automatically
```

### Testing Workflow
```bash
# Run all tests
flutter test

# Run specific test
flutter test test/features/collage/collage_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Code Generation
```bash
# Generate JSON serialization code
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch

# Clean and rebuild
flutter pub run build_runner build --delete-conflicting-outputs
```

## Performance Benchmarks (Expected on M4 Mac)

- **Clean Build**: ~60-90 seconds
- **Incremental Build**: ~3-5 seconds
- **Hot Reload**: <1 second
- **Hot Restart**: ~2-3 seconds
- **Run Tests**: ~5-10 seconds
- **Full Release Build**: ~2-3 minutes

## Next Steps

1. ✅ Set up development environment
2. ✅ Configure Android Studio
3. ✅ Create Flutter project
4. 📝 Implement core features (see [`IMPLEMENTATION_GUIDE.md`](IMPLEMENTATION_GUIDE.md))
5. 📝 Integrate AI services (see [`ARCHITECTURE.md`](ARCHITECTURE.md))
6. 📝 Test and debug
7. 📝 Build release version

## Resources

- [Flutter Mac Setup](https://docs.flutter.dev/get-started/install/macos/mobile-android)
- [Android Studio Guide](https://developer.android.com/studio/intro)
- [M4 Mac Optimization Tips](https://flutter.dev/docs/development/tools/sdk/upgrading)
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

## Support

If you encounter issues specific to Mac M4:
- Check Flutter GitHub issues: https://github.com/flutter/flutter/issues
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: tag [flutter] [macos] [apple-silicon]
