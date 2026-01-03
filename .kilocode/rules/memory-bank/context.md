# Current Context

## Project Status
**Version**: 1.0.0-alpha  
**Last Updated**: January 2, 2026  
**Build Status**: ✅ Compiles and runs successfully on Android

## Recent Changes

### Current Session (Jan 3, 2026)
1. **Web collage flow**: Cached picked image bytes for web builds and render with `Image.memory`, ensuring Chrome now waits for layout generation after selection
2. **Web export support**: Added a download-based export helper that avoids `path_provider` on the web and triggers a PNG download instead of hitting the missing plugin

### Previous Session (Jan 2, 2026)
1. **Fixed Critical Build Error**: Removed deprecated `flutter_ffmpeg` package that was causing Gradle namespace build failures
2. **Confirmed App Launch**: Successfully tested app on Android emulator
3. **Initialized Memory Bank**: Created comprehensive documentation for future sessions

### Session Before That
1. Implemented core collage creation workflow
2. Built AI integration with Ollama and OpenRouter providers
3. Created collage editor with shuffle and export functionality
4. Fixed CardTheme → CardThemeData compatibility issue
5. Updated test files to match new app structure

## Current Work Focus

**Primary Goal**: Core collage features are complete and working. App is stable and ready for feature expansion.

**Next Priorities**:
1. **Settings Screen** - Allow users to configure AI provider preferences
2. **Project Persistence** - Implement save/load with SQLite
3. **Enhanced Editor** - Add background color picker, aspect ratio, and spacing controls
4. **Slideshow Creator** - Begin implementing second major feature

## What's Working Well

- ✅ Image selection from gallery
- ✅ 4 layout algorithms generating instantly
- ✅ Layout preview visualization
- ✅ Collage editor rendering with proper transformations
- ✅ PNG export with high quality (3x pixel ratio)
- ✅ Provider state management architecture
- ✅ Material Design 3 theming

## Known Limitations

1. **AI Not Tested**: AI integration with Ollama and OpenRouter providers has been implemented but NOT tested yet
2. **FFmpeg Removed**: Video export not currently available (needed for slideshows)
3. **Fixed Canvas Size**: Editor uses 1000x1000 canvas which may not scale well for all aspect ratios
4. **AI Parsing**: Regex-based JSON extraction from AI responses can fail with complex outputs
5. **No Persistence**: Projects aren't saved between sessions
6. **Limited Editing**: Can't drag/resize/rotate cells yet

## Next Steps

### Immediate (This Week)
- Implement Settings screen with AI provider configuration
- Add background color picker to collage editor
- Implement aspect ratio selector
- Add home icon/button to return to homepage of application

### Short Term (This Month)
- Build SQLite database for project storage
- Create project gallery screen
- Add JPEG export option
- Implement drag-drop for cells

### Medium Term (Next Month)
- Start slideshow creator implementation
- Add FFmpeg dependency for video export
- Implement transition effects
- Create timeline editor

## Technical Debt to Address

1. Add try-catch blocks throughout for better error handling
2. Implement loading states for all async operations
3. Add input validation
4. Fix withOpacity() deprecation warnings (12 instances)
5. Optimize image loading and memory usage
6. Add undo/redo functionality
7. Implement proper logging system

## Development Environment Notes

- Working in `/Users/sz/StudioProjects/sz_pic_flutter` directory
- Using Mac M4 (Apple Silicon) optimizations
- Android Studio for primary development
- Flutter 3.10.4+ with Material Design 3
- Ollama runs at `http://localhost:11434` for AI features
