# SZ Pic - Implementation Status

> **Source of truth** for current feature status, known issues, and next steps.
> This file was fully refreshed after the September 2026 code review.

---

## 📊 Health Check (September 2026, Windows)

| Check | Result |
|---|---|
| `flutter pub get` | ✅ Works (Flutter 3.38.7 stable / Dart 3.10.7) |
| `flutter analyze` | ✅ 0 errors · 11 warnings · 51 infos |
| `flutter test` | ✅ 1/1 passing (smoke test fixed in this review) |
| Secrets scan (code + full git history) | ✅ Clean |
| Windows desktop build | ⚠️ Not supported — several plugins (`just_audio`, `sqflite`, `permission_handler`) have no/poor Windows support. Target platforms are **Android** and **Web**. |
| CI | ❌ None (no GitHub Actions workflows) |

Project scale: 34 Dart files, ~9,400 lines in `lib/`. Last feature work: January 2026.

---

## ✅ Completed Features

### Core Infrastructure
- Flutter project setup, Android permissions, Provider wiring in `main.dart`
- Material Design 3 theming (light & dark, green seed)
- Cross-platform export helpers (web download vs. native file save)

### Data Models
- `ImageItem`, `CollageLayout`, `LayoutCell`, `CollageProject` (collage)
- `SlideshowProject`, `Slide`, `TransitionEffect` (slideshow)
- `AIProviderConfig`, `AIRecommendation`, layout suggestion request/response
- `MusicTrack`, `PhotoFilter`, `ImageComparison`

### Services
- `CollageEngine` — Grid, Masonry, Template (2–5 image presets), Freestyle layouts
- `ImagePickerService` — gallery/camera, multi-select, web byte caching
- `SlideshowEngine` — slide sequencing and rendering
- `MusicService` / `MusicLibrary` — bundled track playback, volume, fade in/out
- `ImageComparisonService` — before/after comparison support

### Photo Editor (`screens/photo_editor/`)
- 8 filter presets (Original, Vintage, B&W, Cool, Warm, Vibrant, Muted, Dramatic)
- Real-time preview, filter thumbnails, compare-original slider
- PNG/JPEG export

### Collage Creator (`screens/collage/`)
- Layout selection with previews (Grid, Masonry, Template, Freestyle)
- Background color picker (20 presets + custom HSV), aspect ratio, spacing controls
- Freestyle editor: drag, resize, rotate, layer management, shuffle/reset, plus free-crop mode (pan/zoom image within a cell via full-screen crop dialog)
- PNG/JPEG export via RepaintBoundary (3x pixel ratio), user-selected save location

### Slideshow Creator (`screens/slideshow/`)
- Timeline-based editor with preview playback
- Transitions: fade, slide, zoom, Ken Burns (the `dissolve` enum value is hidden from UI — kept only to sanitize legacy saved projects)
- Background music: 3 wired royalty-free tracks (Kevin MacLeod, CC BY 3.0), volume control, preview, auto fade-in/out — **native only** (no `just_audio` on web)
- Export: MP4 video (ffmpeg_kit_flutter_new), PNG sequence, project JSON — **export button hidden on web**

## 🚧 Partial / Inactive

- **AI integration** — `OllamaProvider` (default, wired in `main.dart`) and `OpenRouterProvider` (exists, unwired). Layout suggestions + color analysis implemented at service level but **never tested end-to-end**; there is **no settings UI** and the collage creator's "Apply AI layout" is a TODO stub (`collage_creator_screen.dart:139`). README correctly marks AI as unavailable.

## ⏳ Planned

- Film grain effects — **history**: implemented January 2026, then deliberately replaced by the GPU-accelerated `ColorFiltered` filter system (all film-grain files removed — see `docs/session-history-jan-2026.md`). The home screen "Edit Photo" card subtitle still says "Apply film grain and effects" — fix the copy; only revisit grain if done GPU-side. `plans/film-grain-feature.md` is the old plan.
- Project persistence (SQLite), project gallery, save/load between sessions
- Settings screen (AI provider config, API keys, export quality, theme)
- Drag-and-drop cell editing for grid/masonry/template layouts
- Undo/redo, PDF export, share, text overlays, stickers, custom borders/shadows
- iOS build configuration

---

## 🩺 Code Review Findings (September 2026)

### Bugs / quick fixes
1. ~~Smoke test stale (expected old subtitle and removed menu cards)~~ — **fixed in this review**.
2. `slideshow_editor_screen.dart:1562` — `onError` handler returns `Null` where `FutureOr<File>` is required (`invalid_return_type_for_catch_error`). Latent crash path during video export errors.
3. `home_screen.dart:342` — unnecessary `!` on a non-nullable receiver (warning).
4. Unused code: `_showComingSoon` and `_isHardwareAccelerationLikely` (dead elements), unused `dart:io` import in slideshow creator, unused local `transitionDurationMs`.
5. 3 unused MP3 assets in `assets/music/` (`acoustic_porch_swing_days`, `cinematic_rains_will_fall`, + 1 more on disk than registered in `MusicLibrary`) — either wire them up or remove them from the bundle.

### Analyzer noise (51 infos)
- ~40 × `use_build_context_synchronously` — contexts used across async gaps guarded by "unrelated" mounted checks. Mostly benign but should be tidied (guard with the correct `mounted` or hoist navigator references).
- `withOpacity` deprecated → migrate to `.withValues()`.
- `print()` calls in photo editor → replace with `debugPrint` or a logger.

### Structural / maintenance
- **Monolith screens**: `slideshow_editor_screen.dart` (1,615 lines) and `freestyle_editor_screen.dart` (1,428 lines) with raw `setState`. Extract controllers/sub-widgets before adding features.
- **No test coverage**: single smoke test. Models and engines (CollageEngine, SlideshowEngine, export helpers) are pure logic — easy wins for unit tests.
- **No CI**: no GitHub Actions workflow running analyze/test on PRs.
- **Placeholder Android ID**: `com.example.sz_pic_flutter` in `android/app/build.gradle(.kts)` — must change before any store release.
- **Unpinned dependency**: `ffmpeg_kit_flutter_new: any` in pubspec (lock currently resolves 4.1.0) — pin it for reproducible builds. 76 packages have newer versions; nothing currently blocking.
- **Docs drift (fixed in this review)**: `PROJECT_UPDATE.md` was corrupted (single line of literal `\n` escapes) and claimed MIT license (actual: GPL-3.0); roadmaps predated the slideshow/photo editor work.

---

## 🎯 Recommended Next Steps (priority order)

1. **Set up CI** — GitHub Actions: `flutter analyze` + `flutter test` on push/PR. Cheap and prevents the drift that built up over 8 months.
2. **Fix review findings 2–5** — small diffs, removes all analyzer warnings.
3. **Add unit tests** for `CollageEngine`, `SlideshowEngine`, models, and export helpers.
4. **Pin `ffmpeg_kit_flutter_new`** to a concrete version.
5. **Project persistence (SQLite)** — the biggest user-facing gap; projects vanish on app close.
6. **Settings screen** — unlock AI provider config (OpenRouter key entry) instead of hardcoding Ollama in `main.dart`.
7. **Refactor the two monolith screens** into controllers + widgets before the next feature push.
8. **Redeploy web** (https://szpic.netlify.app/) from current `main`.
9. Fix the home "Edit Photo" card subtitle — it still advertises film grain, which was replaced by the filter system in January 2026.

---

## 🧪 Testing Status

- **Automated**: 1 smoke test (home screen renders, menu cards present) — passing.
- **Manual (last verified January 2026)**: app launches on Android emulator; collage flow, freestyle editor, exports, slideshow creation, music playback, MP4 export all reported working.

## 📝 Known Issues

1. Fixed 1000×1000 editor canvas may not suit all aspect ratios
2. AI response parsing relies on regex JSON extraction — fragile
3. Large images may cause memory pressure on older devices
4. Runtime permission handling incomplete
5. Generic error messages need specificity

---

**Last reviewed**: September 2026 · **Version**: 1.0.0+1 (UI footer says v0.5) · **Status**: Alpha — core features functional; persistence, settings, and AI UI missing
