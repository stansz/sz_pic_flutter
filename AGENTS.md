# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this is

SZ Pic ("SZ Picture Create") — a Flutter app for creating collages, slideshows, and filtered photos. UI footer shows v0.5; pubspec version 1.0.0+1; status: alpha.

- **Supported platforms**: Android (primary; dedicated Pixel 7 test device) and Web (https://szpic.netlify.app/)
- **Not supported**: iOS (unconfigured), desktop (`just_audio`, `sqflite`, `permission_handler` have no desktop implementations)
- **License**: GPL-3.0 — required by FFmpeg Kit GPL libraries; source files carry license headers

## Development environment (September 2026)

- Windows 11, Flutter 3.38.7 stable, **no Android Studio** (deleted; not required)
- JDK: Temurin 21 (`C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot`), wired via `flutter config --jdk-dir`
- Android SDK at the Windows default `%LOCALAPPDATA%\Android\Sdk` (platform-tools, build-tools, licenses accepted)
- Test device: Pixel 7 over USB debugging (`flutter run` targets it automatically when connected)
- Working copy: `C:\Users\sz\Code\sz_pic_flutter` — the **only** local copy; old `~/AndroidStudioProjects` copy deleted after its uncommitted work was rescued

## Read first

- `IMPLEMENTATION_STATUS.md` — current feature state, review findings, prioritized next steps (source of truth)
- `save` branch — WIP auto-save/project-persistence feature (~1,540 lines, analyzer-clean, **untested at runtime**); based on `7255489`, needs rebase onto `main` before merging
- `docs/architecture.md` — accurate architecture reference (models, services, screens, patterns)
- `docs/session-history-jan-2026.md` — detailed change history incl. debugging sagas (ProGuard, video export, Android 14)
- `planning/` — original pre-implementation plans; **partially stale** (aspirational packages/features), trust code over these
- `plans/` — newer feature plans (film grain, auto-save, photo editor redesign)

## Commands

```bash
flutter pub get
flutter analyze --no-fatal-infos   # infos tolerated; errors+warnings fatal. Currently 51 infos, 0 warnings
flutter test                         # smoke test must pass
flutter run                          # Android device/emulator
flutter run -d chrome
flutter build apk --release   # release build (R8 enabled)
flutter build web
```

## Conventions

- **Models**: immutable, extend `Equatable`, `copyWith`, JSON serialization, UUID ids
- **Coordinates**: collage layouts use normalized 0–1 coordinates (resolution-independent); rotation in degrees, scale multiplier
- **DI**: services (`CollageEngine`, `SlideshowEngine`, `ImagePickerService`, `AIProvider`) provided via `MultiProvider` in `main.dart`; screens use `setState` for local state
- **Export**: capture via `RepaintBoundary.toImage(pixelRatio: 3.0)`; PNG internally, JPEG re-encode via `image` package (quality 92)
- **Platform splits**: conditional imports (`export_helper_web.dart` / `export_helper_stub.dart`) and `kIsWeb` guards — keep web/native paths in sync when touching export code
- **Filters**: GPU-accelerated via `ColorFiltered` (see `PhotoFilter` model) — do NOT reintroduce CPU-based per-pixel processing (film grain was removed for this reason)

## Platform gotchas (learned the hard way)

- **Web**: no `just_audio` → music disabled; slideshow export button hidden (`kIsWeb`); picked images cached as `Uint8List` in `ImageItem.bytes`; export via blob download
- **Android release builds**: R8/ProGuard strips plugin classes → crashes (e.g. image_picker platform channel error on Android 14). Rules live in `android/app/proguard-rules.pro`; keep `io.flutter.plugins.**`, Pigeon classes, and plugin classes when adding plugins
- **Video export** (`slideshow_editor_screen.dart`): `ffmpeg_kit_flutter_new ^4.1.0` (pinned; lock = 4.1.0, native `ffmpeg-kit-full-gpl:2.1.0`) — don't bump past 4.x without a device MP4-export test (4.4.1+ changes native binaries; also fixes CVE-2026-8461). Pipeline: PNG frames + concat manifest, even-dimension scaling (`scale=trunc(iw/2)*2:trunc(ih/2)*2`) for libx264, 15fps transitions / 5fps static, temp frame folder cleaned after success. The package ships its own R8 consumer rules since 4.3.1; our `proguard-rules.pro` predates that and keeps other plugins too — keep both.
- **Transitions**: `TransitionType.dissolve` exists in the enum but is hidden from UI (kept only to sanitize legacy saved projects). UI offers fade, slide, zoom, kenBurns
- **Music**: 3 CC-BY Kevin MacLeod tracks wired in `music_library.dart` (attribution in `assets/music/licenses.md`); extra MP3s exist on disk unused — wire up or remove, don't assume the list in code is complete
- **AI**: `OllamaProvider` is the default in `main.dart` (`http://localhost:11434`, `llama3.2-vision`); `OpenRouterProvider` exists unwired. Services implemented but **never tested**; no settings UI; "Apply AI layout" button in collage creator is a TODO stub
- **Android applicationId** is still `com.example.sz_pic_flutter` (placeholder)

## Known structural issues

- `slideshow_editor_screen.dart` (~1,600 lines) and `freestyle_editor_screen.dart` (~1,400 lines) are monoliths — extract controllers before adding features
- Test coverage: 45 unit/widget tests (engines, models, filters, music library) enforced by CI; widget/golden tests for screens still open
- ~40 `use_build_context_synchronously` infos and deprecated `withOpacity` calls remain — prefer `withValues()` in new code

## CI & deployment

- `.github/workflows/web-deploy.yml` runs `flutter analyze` + `flutter test` on every push/PR (pinned to Flutter 3.38.7)
- Pushes to `main` additionally build the web app (`--base-href /sz_pic_flutter/` — required for the project-pages subpath, don't drop it) and deploy to https://stansz.github.io/sz_pic_flutter/
- The old https://szpic.netlify.app/ is a stale manual deploy — GitHub Pages is canonical now
- Keep CI green: zero errors and zero warnings enforced (`--fatal-warnings` default); infos tolerated via `--no-fatal-infos`. Note: plain `flutter analyze` exits 1 on infos in Flutter 3.38+ (`--fatal-infos` defaults on) — always check warnings count, not just exit code

## When you change things

1. Update `IMPLEMENTATION_STATUS.md` if feature state changes
2. Append a session summary to `PROJECT_UPDATE.md`
3. Keep analyzer clean: `flutter analyze` = 0 errors, no new warnings
4. Commits: conventional style (`feat:`, `fix:`, `docs:`, `maint:`)
