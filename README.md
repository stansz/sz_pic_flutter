# SZ Picture Create - AI-Powered Collage & Slideshow Creator

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

SZ Picture Create is a cross-platform mobile application that combines powerful collage and slideshow creation tools with AI-driven creative recommendations. Built with Flutter for seamless performance across Android, iOS, and web platforms.

### Why SZ Picture Create?

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
  - Freestyle: Interactive editor with drag, resize, and rotate
- ✅ **Image Selection**: Multiple images from gallery or camera
- ✅ **AI Suggestions**: Get layout recommendations based on image count
- ✅ **Export Options**: PNG and JPEG (high quality)
- ✅ **Freestyle Editor**: Full interactive editing with drag, resize, rotate, and layer management
- 🚧 **Customization**: Background colors, spacing, aspect ratios (for other layouts)

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



## 🏗️ Architecture

SZ Picture Create follows **Clean Architecture** principles with feature-based organization:

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
│       ├── collage_editor_screen.dart
│       └── freestyle_editor_screen.dart
└── main.dart             # App entry point
```


## 📚 Documentation

- [`GETTING_STARTED.md`](GETTING_STARTED.md) - Setup and installation guide
- [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) - Current feature status


## 🗺️ Roadmap

### Current - Alpha
- ✅ Core collage creation
- ✅ Image picker
- ✅ PNG export
- ✅ JPG export

### Version 1.1 (Next)
- ✅ Freestyle editor with interactive controls
- 🚧 Slideshow creator
- 🚧 Video export
- 🚧 Settings screen
- 🚧 Project management
- 🚧 Web deployment

### Future Versopms
- ⏳ Video export
- ⏳ Cloud storage
- ⏳ Social sharing
- ⏳ iOS support
- ⏳ Web deployment
- ⏳ AI features
- ⏳ Collaboration tools

See [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for detailed progress.


## 🙏 Acknowledgments

- Vibed coded with help of Kilo Code in Android Studio on Macbook M4

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/sz_pic/issues)

---

<div align="center">

[⬆ Back to Top](#sz-pic---ai-powered-collage--slideshow-creator)

</div>
