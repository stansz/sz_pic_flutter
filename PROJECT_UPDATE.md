# SZ Pic - Project Update / Session History

> This file was rebuilt in September 2026: the previous version had become corrupted
> (a single line of literal `\n` escapes, mid-sentence start, contradictory license).
> For **current** status, findings, and next steps see [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md).

---

## September 2026 — Web Feature Parity: Cheap Wins

Focused on closing the web-vs-Android feature gap. Audit showed exactly two features were cut on web, both in the slideshow editor (music playback, export). Both gates removed:

- **Slideshow export sheet now visible on web** — the export button was entirely `kIsWeb`-hidden even though the project-file (JSON) path already contained working web code (blob download). The sheet now offers Video (MP4) on native only and Project File (JSON) everywhere. `_exportVideo` keeps its defensive web guard.
- **Music enabled on web** — removed both `kIsWeb` gates (`_playMusicIfSelected`, `_showMusicOptions`). `just_audio` ships an official web implementation (`just_audio_web`), so the old "no just_audio on web" note was overly cautious. `MusicService` already degrades gracefully (`playTrack` returns `false` → snackbar) if `AudioSession`/playback fails on web.
- Verified: `flutter analyze` (0 errors / 0 warnings, same 51 pre-existing infos), `flutter test` 45/45, `flutter build web` succeeds. **Browser runtime check of music playback still pending** (autoplay policy, `AudioSource.asset` on web).
- Out of scope, noted for later: PNG-sequence export tile (implemented but unlisted in the sheet, native-only); WebM export via `MediaRecorder` as the realistic web video path (ffmpeg.wasm needs COOP/SharedArrayBuffer headers GitHub Pages can't serve).

---

## September 2026 — Code Review & Maintenance

Full review performed on a Windows 11 machine (Flutter 3.38.7 stable / Dart 3.10.7):

- ✅ `flutter pub get`, `flutter analyze` (0 errors), secrets scan all clean
- ✅ Fixed stale smoke test — home screen texts had changed ("SZ Picture Create" / three cards; `My Projects` and `Settings` cards removed in favor of `Edit Photo`)
- ✅ Rebuilt this file, refreshed `README.md`, `IMPLEMENTATION_STATUS.md`, `GETTING_STARTED.md`
- ✅ Migrated Kilo Code memory bank (`.kilocode/rules/memory-bank/`) → root `AGENTS.md` (agent instructions) + `docs/` (architecture, tech-stack, product-vision, session-history); `.kilocode/` removed
- Memory-bank corrections applied to docs: dissolve transition hidden from UI; web audio/slideshow-export disabled; film grain was implemented then replaced by GPU filters; ffmpeg lock resolves 4.1.0
- 🎁 **Rescued ~1,540 lines of uncommitted work** from the old `~/AndroidStudioProjects/sz_pic_flutter` machine copy: the auto-save/project-persistence feature (Project model, SQLite repository, AutoSaveService, ThumbnailGenerator, recent-projects UI) — pushed as the `save` branch (`3d6e52d`). Analyzer-clean, untested at runtime. This work was never logged in the old memory bank.
- Dev environment rebuilt on Windows: Temurin JDK 21 installed (`flutter config --jdk-dir`), Android Studio removed (not required), SDK 36 verified doctor-green; Pixel 7 dedicated as test device
- Repo relocated to `C:\Users\sz\Code\sz_pic_flutter` as the only working copy; old copy deleted after verifying clean tree / no stashes / all branches on GitHub
- **CI + web hosting**: added `.github/workflows/web-deploy.yml` (analyze + test on push/PR; Flutter web build deployed to GitHub Pages on `main`) and enabled Pages via the API. Live at https://stansz.github.io/sz_pic_flutter/ — replaces the stale manual Netlify deploy
- **Cleared all analyzer warnings** (11 → 0) to satisfy CI's zero-warning bar: fixed the `_writeFrameFile` onError type bug, removed dead `_showComingSoon`/`_isHardwareAccelerationLikely`, write-only `_activeCornerId` state, unused import/locals, and a needless `!`. Analyzer now 51 infos, 0 warnings; tests green
- **First device run verified**: `flutter run` on the Pixel 7 — full build/install/launch cycle working (Impeller/Vulkan renderer). Web deploy pipeline verified live end-to-end across three pushes
- **Unit test suite added (45 tests)**: engines, models, filters, music library. Writing them surfaced two real bugs — `removeMusic` was a no-op (`copyWith(musicPath: null)` fallback) and `LayoutCell.copyWith(imageId:)` kept stale ids — both fixed with sentinel-based copyWith and covered by regression tests
- **Pinned `ffmpeg_kit_flutter_new` to `^4.1.0`** (lock-identical, zero diff): closes the silent-upgrade hazard; upgrade to 4.6.x documented as a deliberate, device-tested follow-up (CVE-2026-8461 fix). Also confirmed the ffmpeg origin story (original `flutter_ffmpeg` died with Arthenica's retirement + AGP 8 incompatibility; the Karpenko fork's full-gpl variant supplies libx264)
- Findings and prioritized next steps recorded in [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) (key items: no CI, minimal tests, monolith screens, placeholder Android applicationId, unpinned `ffmpeg_kit_flutter_new`, stale "film grain" home-card copy)

---

## January 2026 — Final Feature Sessions (historical)

Recovered from git history (last commit: Jan 20, 2026, PR #49):

- **Slideshow export transitions** (PR #43) — MP4 export with per-slide transitions
- **Music reliability** (PR #44) — music service fixes, playback indicator
- **Photo editor + navigation** (PR #45/#46) — "Edit Photo" home card, GPL v3 license headers
- **Comparison views** (PR #49) — replaced webview-based comparison with a native widget

Earlier January sessions (from the prior doc):

- Freestyle editor with drag/resize/rotate/layers
- Loading indicators for image processing (LoadingDialog)
- Collage export workflow (PNG/JPEG via `image` package, FilePicker save location, web download)
- Web collage flow with cached picked image bytes
- Removed deprecated `flutter_ffmpeg`; core collage creation, AI providers (Ollama + OpenRouter), freestyle editor completed

---

## License

**GPL-3.0** (required by FFmpeg Kit GPL libraries). See [`LICENSE`](LICENSE).
(The previous version of this file incorrectly stated MIT.)
