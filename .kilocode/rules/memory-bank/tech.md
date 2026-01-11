# Technology Stack

## Core Framework

### Flutter
- **Version**: 3.10.4+
- **SDK**: Dart 3.10.4+
- **Target Platforms**: Android (currently), iOS (planned), Web (planned)
- **Rendering**: Skia graphics engine
- **Hot Reload**: Fast iterative development

### Material Design 3
- `useMaterial3: true`
- `ColorScheme.fromSeed(seedColor: Colors.green)`
- Adaptive light/dark themes
- Elevation and shape system
- CardThemeData, ElevatedButtonThemeData customization

## Dependencies

Located in `/Users/sz/StudioProjects/sz_pic_flutter/pubspec.yaml`

### State Management
- **provider ^6.1.1**: Dependency injection and state sharing
  - Usage: `context.read<Service>()`, `context.watch<Service>()`
  - MultiProvider setup in main.dart
  - Services: ImagePickerService, CollageEngine, AIProvider

### Image Handling
- **image_picker ^1.0.7**: Gallery and camera access
  - `ImageSource.gallery`, `ImageSource.camera`
  - Multiple image selection support
  - Used in [`ImagePickerService`](lib/core/services/image_picker_service.dart:1)
- **image ^4.1.7**: Image processing and metadata extraction
  - Decode images, get dimensions
  - **JPEG Encoding**: Used in export feature to convert PNG to JPEG with quality control
  - `img.encodeJpg(decoded, quality: 92)` for collage exports
- **slideshow_engine** (`lib/core/services/slideshow_engine.dart`): Slideshow project creation and management
  - `createSlideshow()`: Creates SlideshowProject from images
  - `formatDurationLong()`: Formats duration for display
  - Manages slide ordering and transition configuration
- **photo_view ^0.14.0**: Image viewer widget (planned usage)
- **cached_network_image ^3.3.1**: Network image caching (planned)

### HTTP & AI Integration
- **dio ^5.4.0**: Advanced HTTP client
  - Used for Ollama and OpenRouter API calls
  - BaseOptions: timeouts, base URL
  - Interceptors available for logging
- **http ^1.2.0**: Basic HTTP requests (backup)

### Storage
- **shared_preferences ^2.2.2**: Key-value storage
  - Planned: User settings, AI provider config
- **path_provider ^2.1.2**: File system paths
  - Used: getApplicationDocumentsDirectory() for exports
  - Future: thumbnails, cached data
- **sqflite ^2.3.2**: SQLite database
  - Planned: Project storage, image library
- **path ^1.8.3**: Path manipulation utilities

### File Handling
- **file_picker ^8.0.0+1**: Directory and file picker via native dialogs
  - Used: `FilePicker.platform.getDirectoryPath()` for export location selection
  - Prompting user to choose export folder for PNG/JPEG saves
  - Native save dialogs on Android/iOS/Desktop
- **permission_handler ^11.2.0**: Runtime permissions
  - Planned: Request camera, storage permissions

### UI/UX
- **LoadingDialog** (custom widget): Reusable loading UI component
  - Located in [`lib/core/widgets/loading_dialog.dart`](lib/core/widgets/loading_dialog.dart:1)
  - Shows circular progress indicator with message
  - Optional linear progress bar for multi-step operations
  - Static `show()` and `hide()` methods for ease of use
- **flutter_staggered_grid_view ^0.7.0**: Advanced grid layouts
  - Planned: Project gallery, image selection
- **shimmer ^3.0.0**: Loading animations
  - Planned: Skeleton screens

### Video
- **video_player ^2.8.2**: Video playback for slideshow preview
- **ffmpeg_kit_flutter_new 4.1.0**: Video processing for slideshow export
 - Native dependency: `com.antonkarpenko:ffmpeg-kit-full-gpl:2.1.0`
 - Uses concat manifest + `FFmpegKit.execute` in [`_exportVideo()`](lib/screens/slideshow/slideshow_editor_screen.dart:793)
 - Command applies even-dimension scaling (`scale=trunc(iw/2)*2:trunc(ih/2)*2`), `-fps_mode vfr`, `libx264`, `-crf 20`, `-preset veryfast`, `+faststart`
 - Replaces deprecated flutter_ffmpeg / ffmpeg_kit_flutter_min
 - **Robust capture**: Precaches slide images and waits for an extra paint frame before capturing to avoid blank/black frames; per-frame logging records image presence/size and manifest contents

### Utilities
- **uuid ^4.3.3**: Unique ID generation
  - Used: All model IDs
  - `const Uuid().v4()`
- **intl ^0.19.0**: Internationalization
  - Planned: Date formatting, localization
- **equatable ^2.0.5**: Value equality for models
  - All models extend Equatable
  - Simplifies comparisons and debugging

### Dev Dependencies
- **flutter_test**: Testing framework (SDK)
- **flutter_lints ^6.0.0**: Lint rules for code quality

## Development Tools

### Build System
- **Gradle**: Android builds
  - Version: Modern (supports namespace)
  - AGP: Compatible with Flutter 3.10
  - Build time: ~3 minutes (first build), ~30s (incremental)

### IDEs
- **Android Studio**: Primary IDE
  - Flutter and Dart plugins
  - Device emulator management
  - Debugger with breakpoints
- **VS Code**: Alternative with Flutter extension

### Testing Tools
- **Flutter DevTools**: Performance profiling
- **Widget Inspector**: UI debugging
- **Network Inspector**: API call monitoring

## AI Integration

### Ollama (Local)
- **URL**: `http://localhost:11434`
- **Endpoints**: 
  - `/api/generate`: Text generation
  - `/api/tags`: List available models
- **Model**: `llama3.2-vision` (default)
- **Connectivity**: Local network only
- **Response Format**: JSON with streaming option
- **Timeout**: 60 seconds
- **Usage**: Privacy-focused, no API key needed

### OpenRouter (Cloud)
- **URL**: `https://openrouter.ai/api/v1`
- **Endpoint**: `/chat/completions` (OpenAI-compatible)
- **Authentication**: Bearer token (API key)
- **Models**: 
  - `anthropic/claude-3.5-sonnet` (default)
  - `openai/gpt-4-turbo`
  - `google/gemini-pro-vision`
- **Format**: Messages array
- **Timeout**: 30 seconds
- **Usage**: Cloud-based, API key required

## Platform Configuration

### Android
- **Min SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: Latest stable
- **Permissions** (AndroidManifest.xml):
  - READ_EXTERNAL_STORAGE (maxSdk 32)
  - WRITE_EXTERNAL_STORAGE (maxSdk 28)
  - READ_MEDIA_IMAGES (API 33+)
  - READ_MEDIA_VIDEO (API 33+)
  - CAMERA
  - INTERNET
- **Namespace**: com.example.sz_pic_flutter
- **Build**: Kotlin-based Gradle scripts
- **ProGuard Rules**: Created `proguard-rules.pro` to keep plugin classes from obfuscation
  - Keeps Flutter plugin classes (`io.flutter.plugins.**`)
  - Keeps image_picker classes (`io.flutter.plugins.imagepicker.**`)
  - Keeps Pigeon generated classes (`dev.flutter.pigeon.**`)
  - Enabled `isMinifyEnabled = true` for release builds
- **Status**: ✅ Fully functional and tested on Android 14 (Pixel 9a)

### iOS (Planned)
- **Deployment Target**: iOS 12.0+
- **Info.plist Keys**: (to be added)
  - NSPhotoLibraryUsageDescription
  - NSCameraUsageDescription
- **Swift**: 5.0+

### Web
- **Renderer**: CanvasKit (better graphics)
- **Image Handling**: Uses `Image.memory()` with cached bytes
  - Web builds cache `Uint8List` in `ImageItem.bytes` field
  - Avoids file system access limitations
- **Export**: Blob-based download via [`downloadImage()`](lib/core/utils/export_helper_web.dart:1)
  - Creates anchor element with download attribute
  - Triggers automatic download with timestamp filename
- **PWA**: Progressive Web App support (planned)
- **Status**: Basic functionality implemented, needs testing

## Development Environment

### Mac M4 (Apple Silicon)
- **Architecture**: ARM64
- **Android Emulator**: ARM-based images faster
- **Rosetta**: Not needed for Flutter
- **Homebrew**: `/opt/homebrew` prefix
- **Performance**: Excellent (M4 chip)
- **Memory**: Handles multiple emulators

### Setup Commands
```bash
# Flutter
flutter doctor
flutter pub get
flutter run

# Ollama
brew install ollama
ollama serve
ollama pull llama3.2-vision

# Android
sdkmanager --list
flutter create --platforms android,ios,web .
```

## Technical Constraints

1. **Image Memory**: Large images can cause OOM on older devices
   - Mitigation: Resize before processing
   - Future: Use compute() for heavy ops

2. **AI Response Time**: Network-dependent
   - Local Ollama: 1-5 seconds
   - OpenRouter: 2-10 seconds
   - Mitigation: Timeout + fallback

3. **Export Size**: High-res exports (3x) create large files
   - PNG: ~5-10 MB per collage
   - Future: JPEG for smaller size

4. **Canvas Rendering**: Fixed 1000x1000 px
   - Works well for 1:1 aspect
   - Issue: Other aspect ratios may stretch
   - Future: Dynamic sizing

5. **Platform Differences**:
   - Android: File access changing (scoped storage)
   - iOS: Sandbox restrictions
   - Web: Limited file system access

## Code Quality Tools

### Analysis
```bash
flutter analyze --no-fatal-infos
flutter analyze --fatal-warnings
```

### Formatting
```bash
flutter format lib/
```

### Testing (Planned)
```bash
flutter test
flutter test --coverage
flutter test test/models/
```

## Build Commands

### Development
```bash
flutter run                    # Default device
flutter run -d emulator-5554   # Specific device
flutter run --debug            # Debug mode
flutter run --profile          # Profile mode
```

### Release
```bash
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle
flutter build ios              # iOS (Mac only)
flutter build web              # Web build
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

## Version Control

- **Git**: Version control
- **.gitignore**: Excludes build/, .dart_tool/, *.iml
- **Branches**: (to be organized)
  - main: Stable releases
  - develop: Active development
  - feature/*: New features

## Future Technology Additions

1. **Firebase**: Analytics, Crashlytics, Cloud Storage
2. **FFmpeg**: Video processing and export
3. **ML Kit**: On-device image analysis
4. **In-App Purchase**: Premium features
5. **Push Notifications**: Updates and tips
6. **Cloud Functions**: Server-side processing
7. **GraphQL**: Efficient API queries
8. **AR Core/Kit**: AR collage placement
