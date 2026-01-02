# SZ Pic - AI-Powered Collage & Slideshow Creator

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.4+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.4+-0175C2?logo=dart)
![Android](https://img.shields.io/badge/Android-API%2021+-3DDC84?logo=android)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Alpha-yellow)

**Transform your photos into stunning collages and slideshows with AI-powered creative assistance**

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Screenshots](#-screenshots) • [Contributing](#-contributing)

</div>

---

## 🎨 Overview

SZ Pic is a cross-platform mobile application that combines powerful collage and slideshow creation tools with AI-driven creative recommendations. Built with Flutter for seamless performance across Android, iOS, and web platforms.

### Why SZ Pic?

- **🤖 AI-Powered**: Get intelligent layout suggestions and creative recommendations
- **🎭 Multiple Layouts**: Grid, Masonry, Template, and Freestyle arrangements
- **🎬 Rich Slideshows**: Create dynamic presentations with transitions and music
- **🔒 Privacy-First**: Use local Ollama AI or cloud-based OpenRouter
- **📱 Cross-Platform**: Single codebase for Android, iOS, and Web
- **🎨 Intuitive Design**: Material Design 3 with beautiful themes

## ✨ Features

### Collage Creator
- ✅ **4 Layout Algorithms**
  - Grid: Evenly distributed cells
  - Masonry: Pinterest-style cascading
  - Template: Pre-designed 2-5 image layouts
  - Freestyle: Random positioning with rotation
- ✅ **Image Selection**: Multiple images from gallery or camera
- ✅ **AI Suggestions**: Get layout recommendations based on image count
- ✅ **Export Options**: PNG (high quality)
- 🚧 **Customization**: Background colors, spacing, aspect ratios
- 🚧 **Advanced Editing**: Drag-drop, resize, rotate cells

### AI Integration
- ✅ **Dual Provider Support**
  - Ollama: Local, privacy-first AI processing
  - OpenRouter: Cloud-based with multiple models
- ✅ **Layout Recommendations**: AI-suggested arrangements
- ✅ **Color Scheme Analysis**: Complementary color suggestions
- 🚧 **Image Enhancement**: Filter and improvement suggestions

### Slideshow Creator (Planned)
- ⏳ Timeline-based editor
- ⏳ Transition effects (Fade, Slide, Zoom, Dissolve, Ken Burns)
- ⏳ Music integration
- ⏳ Video export (MP4, MOV, GIF)

### Additional Features
- ✅ Material Design 3 theming (Light & Dark modes)
- ✅ Provider state management
- ✅ Efficient image caching
- ⏳ Project save/load
- ⏳ Cloud storage integration
- ⏳ Social sharing

## 🚀 Quick Start

### Prerequisites
- Mac M4 (Apple Silicon) or compatible system
- Flutter 3.10.4+
- Android Studio or VS Code
- Ollama (for local AI) - optional

### Installation

```bash
# Clone the repository
cd /Users/sz/StudioProjects/sz_pic_flutter

# Install dependencies
flutter pub get

# Run the app
flutter run
```

For detailed setup instructions, see [`GETTING_STARTED.md`](GETTING_STARTED.md).

### Quick AI Setup (Optional)

```bash
# Install Ollama
brew install ollama

# Start Ollama
ollama serve

# Pull vision model
ollama pull llama3.2-vision
```

## 📱 Screenshots

### Home Screen
Beautiful gradient design with easy navigation to all features.

### Collage Creator
Choose from 4 layout algorithms with visual previews.

### Collage Editor
Edit and customize your collage with intuitive controls.

### AI Suggestions
Get AI-powered layout recommendations in seconds.

## 🏗️ Architecture

SZ Pic follows **Clean Architecture** principles with feature-based organization:

```
lib/
├── core/
│   ├── models/           # Data models (Equatable)
│   │   ├── image_item.dart
│   │   ├── collage_models.dart
│   │   ├── slideshow_models.dart
│   │   └── ai_models.dart
│   └── services/         # Business logic
│       ├── ai_provider.dart        # Abstract AI interface
│       ├── ollama_provider.dart    # Local AI implementation
│       ├── openrouter_provider.dart # Cloud AI implementation
│       ├── collage_engine.dart     # Layout algorithms
│       └── image_picker_service.dart
├── screens/              # UI screens
│   ├── home_screen.dart
│   └── collage/
│       ├── collage_creator_screen.dart
│       └── collage_editor_screen.dart
└── main.dart             # App entry point
```

### Key Technologies
- **State Management**: Provider
- **UI Framework**: Flutter Material Design 3
- **Image Processing**: `image` package
- **Networking**: Dio for AI API calls
- **Storage**: SQLite + SharedPreferences
- **AI**: Ollama (local) + OpenRouter (cloud)

## 📚 Documentation

- [`GETTING_STARTED.md`](GETTING_STARTED.md) - Setup and installation guide
- [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) - Current feature status
- [`planning/ARCHITECTURE.md`](planning/ARCHITECTURE.md) - Technical architecture details
- [`planning/MAC_M4_SETUP_GUIDE.md`](planning/MAC_M4_SETUP_GUIDE.md) - Mac M4 optimizations

## 🧪 Testing

### Manual Testing
```bash
# Run in debug mode
flutter run --debug

# Run in release mode (better performance)
flutter run --release
```

### Automated Testing (Coming Soon)
```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart
```

## 🔧 Configuration

### Switch to OpenRouter (Cloud AI)

Edit [`lib/main.dart`](lib/main.dart):

```dart
Provider<AIProvider>(
  create: (_) => OpenRouterProvider(
    config: AIProviderConfig.defaultOpenRouter(
      apiKey: 'YOUR_OPENROUTER_API_KEY',
    ),
  ),
),
```

### Customize Theme

Edit [`lib/main.dart`](lib/main.dart):

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, // Change this
    brightness: Brightness.light,
  ),
  useMaterial3: true,
),
```

## 🗺️ Roadmap

### Version 1.0 (Current - Alpha)
- ✅ Core collage creation
- ✅ Basic AI integration
- ✅ Image picker
- ✅ PNG export

### Version 1.1 (Next)
- 🚧 Advanced collage editing
- 🚧 Settings screen
- 🚧 Project management
- 🚧 JPEG/PDF export

### Version 2.0 (Future)
- ⏳ Slideshow creator
- ⏳ Video export
- ⏳ Cloud storage
- ⏳ Social sharing

### Version 3.0 (Future)
- ⏳ iOS support
- ⏳ Web deployment
- ⏳ Advanced AI features
- ⏳ Collaboration tools

See [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for detailed progress.


### Development Workflow

```bash
# Create a feature branch
git checkout -b feature/amazing-feature

# Make changes
# ...

# Format code
flutter format lib/

# Analyze
flutter analyze

# Test
flutter test

# Commit and push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature
```

## 📦 Dependencies

### Core
- `flutter` - Flutter SDK
- `provider` - State management
- `equatable` - Value equality

### Image Handling
- `image_picker` - Gallery/camera access
- `image` - Image processing
- `photo_view` - Image viewing

### Networking
- `dio` - HTTP client for AI APIs
- `http` - Basic HTTP requests

### Storage
- `shared_preferences` - Key-value storage
- `path_provider` - File paths
- `sqflite` - Local database

### UI/UX
- `flutter_staggered_grid_view` - Grid layouts
- `cached_network_image` - Image caching
- `shimmer` - Loading animations

### Utilities
- `uuid` - Unique IDs
- `path` - Path manipulation
- `intl` - Internationalization

See [`pubspec.yaml`](pubspec.yaml) for complete list.

## 📄 License



## 🙏 Acknowledgments

- Vibed coded with help of Kilo Code (and mostly Claude Sonnet 4.5)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/sz_pic/issues)

---

<div align="center">

**Built with ❤️ using Flutter**

[⬆ Back to Top](#sz-pic---ai-powered-collage--slideshow-creator)

</div>
