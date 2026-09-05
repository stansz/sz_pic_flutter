# SZ Picture Create - AI-Powered Collage & Slideshow Creator

Web Version: 
https://szpic.netlify.app/

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.4+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.4+-0175C2?logo=dart)
![Android](https://img.shields.io/badge/Android-API%2021+-3DDC84?logo=android)
![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)
![Status](https://img.shields.io/badge/Status-Alpha-yellow)

**Transform your photos into stunning collages and slideshows with AI-powered creative assistance**

</div>

---

## 🎨 Overview

SZ Picture Create is a cross-platform mobile application that combines powerful editing, collage and slideshow creation tools with AI-driven creative recommendations. Built with Flutter for seamless multi platform performance.

## ✨ Features

### Photo Editor
- ✅ **GPU-Accelerated Filters**: Real-time 60fps preview using Flutter's ColorFiltered widget
- ✅ **8 Filter Presets**: Original, Vintage, Black & White, Cool, Warm, Vibrant, Muted, Dramatic
- ✅ **Instagram-Style Selector**: Horizontal filter picker with visual thumbnails
- ✅ **Instant Switching**: Zero lag between filters with GPU rendering
- ✅ **Export Options**: PNG and JPEG with filter applied
- ✅ **High-Quality Capture**: 3x pixel ratio for print-quality exports

### Collage Creator
- ✅ **4 Layout Algorithms**
  - Grid: Evenly distributed cells
  - Masonry: Pinterest-style cascading
  - Template: Pre-designed 2-5 image layouts
  - Freestyle: Interactive editor with drag, resize, and rotate
- ✅ **Image Selection**: Multiple images from gallery or camera
- ✅ **Background Color Picker**: 20 preset colors + custom HSV sliders
- ✅ **Aspect Ratio Selector**: 1:1, 4:3, 3:2, 16:9, 3:4, 9:16
- ✅ **Spacing Adjustment**: 0-50% with "Closer/Further" labels
- ✅ **Free Crop Mode**: Precise image positioning within cells (freestyle editor)
- ✅ **Export Options**: PNG and JPEG with user-selected save location
- ✅ **Freestyle Editor**: Full interactive editing with drag, resize, rotate, and layer management
- ⏳ **AI Suggestions**: Get layout recommendations based on image count

### Slideshow Creator
- ✅ **Timeline-Based Editor**: Visual slide preview with playback controls
- ✅ **Transition Effects**: Fade, Slide, Zoom, Ken Burns
- ✅ **Background Music**: 3 bundled royalty-free tracks (Kevin MacLeod, CC BY 3.0)
  - "Carefree" (Upbeat)
  - "Dream Culture" (Nostalgic)
  - "Atlantean Twilight" (Ambient/Chill)
- ✅ **Volume Control**: Slider for audio adjustment
- ✅ **Music Preview**: Preview tracks before selection
- ✅ **Video Export**: MP4 with audio support, optimized frame rates (15fps transitions, 5fps static)
- ✅ **PNG Sequence Export**: Individual slide images
- ✅ **Project File Export**: JSON for saving/loading projects
- ✅ **Automatic Fade-In/Out**: Smooth audio transitions synchronized with slideshow

### AI Integration
- ⏳ **Dual Provider Support**
  - Ollama: Local, privacy-first AI processing
  - OpenRouter: Cloud-based with multiple models
- ⏳ **Layout Recommendations**: AI-suggested arrangements
- ⏳ **Color Scheme Analysis**: Complementary color suggestions
- ⏳ **Image Enhancement**: Filter and improvement suggestions

> **Note**: AI features are currently in development and not yet available for use. There is no settings UI yet — the app defaults to a local Ollama instance (`http://localhost:11434`) configured in `lib/main.dart`.

## 🩺 Current Status (September 2026)

A full code review was completed in September 2026 (see [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for findings and next steps). Summary:

- ✅ `flutter pub get` / `flutter analyze` clean (0 errors) / `flutter test` green on Flutter 3.38.7
- ✅ No secrets in code or git history
- ⚠️ Test coverage is minimal (one smoke test); no CI; docs were stale and have been refreshed

The web version at https://szpic.netlify.app/ may lag behind `main` — redeploy after pulling recent changes.

## 🗺️ Roadmap

- ✅ Web deployment (https://szpic.netlify.app/) — basic functionality
- ⏳ Fix "Edit Photo" home-card copy (still advertises film grain, which was replaced by the GPU filter system in Jan 2026)
- ⏳ Cloud storage
- ⏳ Social sharing
- ⏳ iOS support
- ⏳ AI features testing
- ⏳ Project persistence (SQLite)
- ⏳ Project gallery screen
- ⏳ Settings screen (incl. AI provider configuration)
- ⏳ Undo/redo, drag-and-drop editing for grid/masonry/template layouts

See [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for detailed progress.


## 📄 License

This project is licensed under the **GNU General Public License v3.0**.

The project uses FFmpeg Kit with GPL libraries, which requires the entire application to be licensed under GPL v3.

See the [LICENSE](LICENSE) file for the full license text.

## 🙏 Acknowledgments & AI/Vibe Coding Warning

- Vibed coded with help of help of Kilo Code in Android Studio

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/stansz/sz_pic_flutter/issues)

---

<div align="center">

[⬆ Back to Top](#sz-pic---ai-powered-collage--slideshow-creator)

</div>
