# Getting Started with SZ Pic

This guide gets SZ Pic running on **Windows** or **macOS**. Verified September 2026 on Windows 11 with Flutter 3.38.7 stable / Dart 3.10.7.

> Target platforms: **Android** and **Web**. Windows/macOS/Linux desktop builds are not supported (audio/database/permission plugins have no desktop implementations).

## Prerequisites

- Flutter SDK (stable channel) — [install guide](https://docs.flutter.dev/get-started/install)
- VS Code (or Android Studio) with the Flutter plugin — the IDE is your choice, neither is mandatory beyond the SDK
- Android SDK + an emulator or a physical device with USB debugging
- A JDK for Android/Gradle builds (e.g. [Temurin 21](https://adoptium.net); point Flutter at it with `flutter config --jdk-dir "<path>"`) — not needed for web-only work
- For local AI features: [Ollama](https://ollama.com) (optional)

```bash
flutter doctor   # resolve anything reported here before continuing
```

## Get the Project Running

```bash
git clone https://github.com/stansz/sz_pic_flutter
cd sz_pic_flutter

flutter pub get     # fetch dependencies
flutter analyze     # should report 0 errors
flutter test        # smoke test should pass

flutter devices     # pick a target
flutter run         # Android emulator/device
flutter run -d chrome   # web
```

### Windows note

If `pub get` warns about symlink support for plugin builds, enable Developer Mode:
`start ms-settings:developers` (this only matters for Windows desktop builds, which are unsupported anyway — Android/web are unaffected).

## Optional: Local AI (Ollama)

```bash
ollama serve
ollama pull llama3.2-vision
```

The app connects to `http://localhost:11434` by default (configured in `lib/main.dart`).
To use OpenRouter instead, swap the provider in `lib/main.dart`:

```dart
Provider<AIProvider>(
  create: (_) => OpenRouterProvider(
    config: AIProviderConfig.defaultOpenRouter(
      apiKey: 'YOUR_API_KEY_HERE',
    ),
  ),
),
```

> AI features are still in development — see [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md).

## Feature Walkthrough

### Create a Collage
1. Tap **Create Collage**
2. Select 2–5 images
3. Choose a layout (Grid, Masonry, Template, or Freestyle)
4. Freestyle: tap to select, drag to move, corner handle to resize, top handle to rotate, **Layers** button for z-order, Shuffle/Reset for quick changes
5. Export as PNG or JPEG

### Create a Slideshow
1. Tap **Create Slideshow**, select images
2. Arrange slides, set durations and transitions (fade, slide, zoom, Ken Burns)
3. Optionally add background music (3 bundled CC-BY tracks) with volume control — native only, disabled on web
4. Export as MP4 video, PNG sequence, or project JSON — export is hidden on web builds

### Edit a Photo
1. Tap **Edit Photo**, select an image
2. Apply one of 8 filter presets, compare with original
3. Export as PNG or JPEG

## Project Structure

```
lib/
├── core/
│   ├── models/          # image_item, collage_models, slideshow_models,
│   │                    # ai_models, music_track, photo_filter, image_comparison
│   ├── services/        # collage_engine, slideshow_engine, music_service,
│   │                    # image_picker_service, ai_provider, ollama_provider,
│   │                    # openrouter_provider, image_comparison_service
│   ├── utils/           # export_helper (+ web/stub variants)
│   └── widgets/         # reusable UI (color picker, filters, comparison slider, dialogs)
├── screens/
│   ├── home_screen.dart
│   ├── collage/         # creator, editor, freestyle editor
│   ├── slideshow/       # creator, editor
│   └── photo_editor/    # photo editor
└── main.dart
```

## Common Issues

| Problem | Fix |
|---|---|
| `flutter: command not found` | Add Flutter's `bin` to your PATH |
| Ollama connection failed | `ollama serve` running? model pulled (`ollama list`)? |
| No devices found | Start the emulator first; verify with `flutter devices`; enable USB debugging on physical devices |
| Image picker denied | Grant photos permission (Android Settings → Apps → SZ Pic → Permissions) |
| Gradle build error | `cd android && ./gradlew clean && cd ..` then retry |
| Slow emulator | Prefer ARM64 images (Apple Silicon) or hardware-accelerated x86 (Windows); test on a real device for best results |

## Development Tips

- `r` hot reload / `R` hot restart / `q` quit (while `flutter run` is attached)
- `flutter analyze` before every commit; `flutter test` to run the smoke test
- Logs: `flutter logs` or the Run console

## Next Steps

- Review [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for the current state, review findings, and prioritized next steps
- [`AGENTS.md`](AGENTS.md) — instructions for AI coding agents (conventions, gotchas, commands)
- [`docs/architecture.md`](docs/architecture.md) — accurate architecture reference; [`docs/tech-stack.md`](docs/tech-stack.md) — dependency notes
- [`docs/session-history-jan-2026.md`](docs/session-history-jan-2026.md) — detailed change history and debugging notes
- [`planning/ARCHITECTURE.md`](planning/ARCHITECTURE.md) — original (partially stale) pre-implementation architecture

---

**Last Updated**: September 2026 · **Verified with**: Flutter 3.38.7 / Dart 3.10.7 (Windows 11)
