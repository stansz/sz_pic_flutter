# Film Grain Feature Implementation Plan

## Overview
Add a standalone film grain feature that allows users to apply cinematic grain effects to individual photos. This feature will be accessible from the home screen as a new "Edit Photo" card and will provide both preset-based and custom grain controls.

## Feature Requirements

### User Flow
```
Home Screen → Select Photo → Photo Editor Screen
                                    ↓
                            Apply Grain Preset or Custom Controls
                                    ↓
                            Real-time Preview
                                    ↓
                            Export Image (PNG/JPEG)
```

### Key Features
1. **5 Film Grain Presets**:
   - Vintage: Warm, medium grain with slight sepia tint
   - B&W: Classic black & white film grain
   - Color: Modern color film grain (neutral)
   - Fine: Subtle, high-frequency grain for minimal effect
   - Coarse: Heavy, low-frequency grain for dramatic effect

2. **Custom Grain Controls**:
   - Grain Intensity: 0-100% slider
   - Grain Size: Fine to Coarse (1-10 scale)
   - Blend Mode: Normal, Overlay, Soft Light, Hard Light
   - Color Tint: Optional color overlay (for vintage look)

3. **Export Options**:
   - PNG (high quality)
   - JPEG (smaller file size)
   - User-selected save location

## Architecture

### New Models
**File**: `lib/core/models/film_grain_models.dart`

```dart
enum FilmGrainPreset {
  vintage,
  bw,
  color,
  fine,
  coarse,
}

class FilmGrainSettings {
  final FilmGrainPreset? preset;
  final double intensity; // 0.0 to 1.0
  final double size; // 1.0 to 10.0
  final BlendMode blendMode;
  final Color? tintColor;
  
  // Factory methods for presets
  factory FilmGrainSettings.vintage() { ... }
  factory FilmGrainSettings.bw() { ... }
  // etc.
}
```

### New Service
**File**: `lib/core/services/film_grain_service.dart`

**Responsibilities**:
- Generate grain texture using `image` package
- Apply grain to images with specified settings
- Handle different blend modes
- Optimize performance (use `compute` for heavy operations)

**Key Methods**:
```dart
class FilmGrainService {
  // Generate grain texture
  img.Image generateGrainTexture(int width, int height, double intensity, double size);
  
  // Apply grain to image
  Future<img.Image> applyGrain(img.Image source, FilmGrainSettings settings);
  
  // Convert image with grain to bytes
  Future<Uint8List> imageToBytes(img.Image image, String format);
}
```

**Grain Generation Algorithm**:
- Use random noise generation
- Apply Gaussian blur for size control
- Adjust intensity via alpha blending
- Support color tinting for vintage effects

### New Screens
**File**: `lib/screens/photo_editor/photo_editor_screen.dart`

**Components**:
- Image preview with grain overlay
- Preset selector (horizontal scrollable cards)
- Custom grain controls (sliders, dropdowns)
- Export button with format selection
- Loading states during grain processing

**State Management**:
```dart
class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  ImageItem _selectedImage;
  FilmGrainSettings _grainSettings;
  bool _isProcessing = false;
  bool _showCustomControls = false;
  
  // Methods
  void _applyPreset(FilmGrainPreset preset);
  void _updateGrainSettings(FilmGrainSettings newSettings);
  Future<void> _exportImage(CollageExportFormat format);
}
```

### New Widgets

**File**: `lib/core/widgets/grain_preset_selector.dart`
- Horizontal scrollable list of preset cards
- Visual preview of each preset (thumbnail with grain applied)
- Tap to apply preset
- Selected state indicator

**File**: `lib/core/widgets/grain_controls.dart`
- Grain intensity slider (0-100%)
- Grain size slider (Fine to Coarse)
- Blend mode dropdown
- Color tint picker (optional)
- Reset button

**File**: `lib/core/widgets/film_grain_overlay.dart`
- CustomPainter widget for real-time grain preview
- Efficient rendering using ShaderMask or CustomPainter
- Supports dynamic grain intensity and size
- Optimized for 60fps performance

### Home Screen Integration
**File**: `lib/screens/home_screen.dart`

Add new menu card between existing cards:
```dart
_MenuCard(
  icon: Icons.edit_photo,
  title: 'Edit Photo',
  subtitle: 'Apply film grain and effects',
  color: theme.colorScheme.tertiary,
  onTap: _isLoading ? null : () => _navigateToPhotoEditor(context),
  isLoading: _isLoading,
),
```

Add navigation method:
```dart
Future<void> _navigateToPhotoEditor(BuildContext context) async {
  // Pick single image
  final imagePickerService = context.read<ImagePickerService>();
  final image = await imagePickerService.pickImage(ImageSource.gallery);
  
  if (image != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoEditorScreen(image: image),
      ),
    );
  }
}
```

## Technical Implementation Details

### Grain Generation Algorithm

**Approach 1: Pixel-based Noise (Simple)**
```dart
img.Image generateGrainTexture(int width, int height, double intensity, double size) {
  final grain = img.Image(width: width, height: height);
  final random = math.Random();
  
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final noise = random.nextDouble() * 255 * intensity;
      grain.setPixelRgba(x, y, noise, noise, noise, 255);
    }
  }
  
  // Apply blur for size control
  if (size > 1.0) {
    return img.gaussianBlur(grain, radius: size.toInt());
  }
  
  return grain;
}
```

**Approach 2: Perlin Noise (Better Quality)**
- Use perlin noise for more natural grain
- Better for large grain sizes
- More computationally expensive

**Recommendation**: Start with pixel-based noise, optimize if needed.

### Blend Modes

Support 4 blend modes using `image` package:
- `Normal`: Simple alpha blending
- `Overlay`: Increases contrast
- `Soft Light`: Subtle contrast enhancement
- `Hard Light`: Strong contrast enhancement

### Performance Optimizations

1. **Debounce Grain Updates**: Don't regenerate grain on every slider change
2. **Use compute()**: Heavy image processing on isolate
3. **Preview Resolution**: Use lower resolution for preview, high for export
4. **Cache Grain Textures**: Reuse grain textures when settings don't change
5. **Progressive Loading**: Show loading indicator during grain application

### Export Process

```dart
Future<void> _exportImage(CollageExportFormat format) async {
  setState(() => _isProcessing = true);
  
  try {
    // Load image at full resolution
    img.Image source = img.decodeImage(File(_selectedImage.path).readAsBytesSync());
    
    // Apply grain
    img.Image withGrain = await compute(
      FilmGrainService.applyGrain,
      [source, _grainSettings],
    );
    
    // Convert to bytes
    Uint8List bytes;
    if (format == CollageExportFormat.png) {
      bytes = Uint8List.fromList(img.encodePng(withGrain));
    } else {
      bytes = Uint8List.fromList(img.encodeJpg(withGrain, quality: 92));
    }
    
    // Save to user-selected location
    await _saveImage(bytes, format);
    
  } catch (e) {
    _showError('Export failed: $e');
  } finally {
    setState(() => _isProcessing = false);
  }
}
```

## UI Design

### Photo Editor Screen Layout

```
┌─────────────────────────────────────┐
│  ← Edit Photo          Export Save │  AppBar
├─────────────────────────────────────┤
│                                     │
│         [Image Preview]             │
│      (with grain overlay)            │
│                                     │
├─────────────────────────────────────┤
│  Presets:                           │
│  [Vintage] [B&W] [Color] [Fine]    │
│  [Coarse]                           │
├─────────────────────────────────────┤
│  Custom Controls:                    │
│  Intensity: [====|====] 50%        │
│  Size:      [==|======] 70%        │
│  Blend:     [Normal ▼]              │
│  Tint:      [Color Picker]          │
├─────────────────────────────────────┤
│  [Reset] [Compare] [Export]        │  Bottom controls
└─────────────────────────────────────┘
```

### Preset Cards Design

Each preset card shows:
- Icon representing the preset style
- Preset name
- Small thumbnail with grain applied
- Selected state (border/check icon)

### Color Scheme

- Primary action: `theme.colorScheme.primary`
- Secondary action: `theme.colorScheme.secondary`
- Tertiary action: `theme.colorScheme.tertiary` (Edit Photo card)
- Background: Gradient matching home screen

## File Structure

```
lib/
├── core/
│   ├── models/
│   │   └── film_grain_models.dart          # NEW
│   ├── services/
│   │   └── film_grain_service.dart         # NEW
│   └── widgets/
│       ├── grain_preset_selector.dart       # NEW
│       ├── grain_controls.dart              # NEW
│       └── film_grain_overlay.dart         # NEW
├── screens/
│   ├── photo_editor/
│   │   └── photo_editor_screen.dart       # NEW
│   └── home_screen.dart                   # MODIFIED
```

## Dependencies

**Existing Dependencies** (already in pubspec.yaml):
- `image ^4.1.7`: For image processing
- `file_picker ^10.3.8`: For save location selection
- `provider ^6.1.1`: For state management (if needed)

**No new dependencies required** - using existing `image` package for grain generation.

## Testing Strategy

### Unit Tests
- `FilmGrainService` methods
- Grain generation algorithms
- Blend mode calculations

### Widget Tests
- `GrainPresetSelector` widget
- `GrainControls` widget
- `PhotoEditorScreen` UI interactions

### Integration Tests
- Complete flow: Select image → Apply grain → Export
- Preset application
- Custom control adjustments
- Export functionality

### Manual Testing
- Test on Android emulator
- Test with different image sizes
- Test with all presets
- Test export to different formats
- Performance testing with large images

## Performance Considerations

1. **Image Size**: Large images (>4000px) may cause memory issues
   - Solution: Resize to max 3000px before processing
   
2. **Grain Generation**: Can be slow for large images
   - Solution: Use `compute()` to move to isolate
   
3. **Real-time Preview**: Updating grain on every slider change is expensive
   - Solution: Debounce updates (wait 300ms after last change)
   
4. **Memory Usage**: Holding multiple image copies
   - Solution: Dispose unused images promptly

## Known Limitations

1. **Web Platform**: Grain generation may be slower on web
   - Solution: Show loading indicator, consider web workers
   
2. **Very Large Images**: May cause OOM on older devices
   - Solution: Add image size warning, auto-resize if needed
   
3. **Blend Modes**: Limited to 4 modes initially
   - Future: Add more blend modes if needed

## Future Enhancements

1. **More Presets**: Add additional film types (Kodak, Fujifilm, etc.)
2. **Vignette**: Add vignette effect alongside grain
3. **Color Grading**: Add color grading controls
4. **Batch Processing**: Apply grain to multiple images at once
5. **Undo/Redo**: Support undo/redo for grain adjustments
6. **Save Presets**: Allow users to save custom grain settings as presets
7. **AI Enhancement**: Use AI to suggest best grain settings for each image

## Success Criteria

- ✅ Users can select a single photo from gallery
- ✅ 5 grain presets are available and working
- ✅ Custom grain controls (intensity, size, blend mode, tint) are functional
- ✅ Real-time preview shows grain effect
- ✅ Export works for both PNG and JPEG formats
- ✅ Performance is acceptable (<3 seconds for grain application)
- ✅ No crashes or memory leaks
- ✅ UI follows Material Design 3 guidelines
- ✅ Feature integrates seamlessly with existing app

## Implementation Order

1. Create models and service (core logic)
2. Create reusable widgets (UI components)
3. Create PhotoEditorScreen (main feature screen)
4. Integrate with HomeScreen (navigation)
5. Add export functionality
6. Test and optimize
7. Update documentation

## Notes

- Follow existing code patterns (Provider, Material Design 3)
- Use `LoadingDialog` for loading states
- Follow the architecture defined in memory bank
- Keep grain generation efficient for mobile devices
- Test on Android emulator before considering complete
