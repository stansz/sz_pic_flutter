# Technology Stack

> Migrated September 2026 from `.kilocode/rules/memory-bank/tech.md` (Kilo Code memory bank).
> Accurate as of January 2026. Note: paths reference the original dev machine
> (`C:/Users/sz/AndroidStudioProjects/sz_pic_flutter`); the repo now lives wherever you cloned it.
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

Located in `C:/Users/sz/AndroidStudioProjects/sz_pic_flutter/pubspec.yaml`

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
- **photo_view ^0.15.0**: Image viewer widget
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
- **file_picker ^10.3.8**: Directory and file picker via native dialogs
  - Used: `FilePicker.platform.getDirectoryPath()` for export location selection
  - Prompting user to choose export folder for PNG/JPEG saves
  - Native save dialogs on Android/iOS/Desktop
- **permission_handler ^12.0.1**: Runtime permissions
  - Used: Request camera, storage permissions

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

### Audio (Music Playback)
- **just_audio ^0.9.37**: Audio playback service for slideshow background music
  - Used by MusicService for track playback, loop mode, volume control
  - Supports fade transitions and concurrent call protection
- **audio_session ^0.1.16**: Audio session management
  - Configures proper background playback for music

### Video
- **video_player ^2.8.2**: Video playback for slideshow preview
- **ffmpeg_kit_flutter_new 4.1.0**: Video processing for slideshow export
 - Native dependency: `com.antonkarpenko:ffmpeg-kit-full-gpl:2.1.0`
 - Uses concat manifest + `FFmpegKit.execute` in [`_exportVideo()`](lib/screens/slideshow/slideshow_editor_screen.dart:793)
 - Command applies even-dimension scaling (`scale=trunc(iw/2)*2:trunc(ih/2)*2`), `-fps_mode vfr`, `libx264`, `-crf 20`, `-preset ultrafast`, `+faststart`
 - Replaces deprecated flutter_ffmpeg / ffmpeg_kit_flutter_min
 - **Optimized capture**: 15fps for transitions, 5fps for static slides (single frame with concat duration)
 - **Audio support**: Includes bundled music tracks in video export

### Utilities
- **uuid ^4.3.3**: Unique ID generation
  - Used: All model IDs
  - `const Uuid().v4()`
- **intl ^0.20.2**: Internationalization
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
- **Audio**: Disabled on web builds (no just_audio support)
- **PWA**: Progressive Web App support (planned)
- **Status**: Basic functionality implemented, needs testing

## Development Environment

### Windows 11
- **Architecture**: x64
- **Android Emulator**: Standard Android emulator
- **Development**: Android Studio
- **Performance**: Good for Flutter development

### Setup Commands
```bash
# Flutter
flutter doctor
flutter pub get
flutter run

# Ollama
# Run locally at http://localhost:11434
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
   - JPEG: Smaller size with quality control

4. **Canvas Rendering**: Fixed 1000x1000 px
   - Works well for 1:1 aspect
   - Issue: Other aspect ratios may stretch
   - Future: Dynamic sizing

5. **Platform Differences**:
   - Android: File access changing (scoped storage)
   - iOS: Sandbox restrictions
   - Web: Limited file system access, no audio playback

6. **Video Export Performance**: GPU surface loss with high frame rates
   - Mitigation: Reduced frame rates (15fps transition, 5fps static)
   - Single frame capture for static slides with concat demuxer duration

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

## Assets

### Music Assets (Bundled)
Located in `assets/music/`:
- `upbeat_carefree.mp3` - "Carefree" by Kevin MacLeod (CC BY 3.0)
- `nostalgic_dream_culture.mp3` - "Dream Culture" by Kevin MacLeod (CC BY 3.0)
- `ambient_atlantean_twilight.mp3` - "Atlantean Twilight" by Kevin MacLeod (CC BY 3.0)
- `licenses.md` - Full attribution and license information

## Future Technology Additions

1. **Firebase**: Analytics, Crashlytics, Cloud Storage
2. **ML Kit**: On-device image analysis
3. **In-App Purchase**: Premium features
4. **Push Notifications**: Updates and tips
5. **Cloud Functions**: Server-side processing
6. **GraphQL**: Efficient API queries
7. **AR Core/Kit**: AR collage placement
8. **User Music Library**: Allow selecting music from device
