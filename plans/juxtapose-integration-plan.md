# Juxtapose Integration Plan - Before/After Image Comparison

## Overview

Implement a before/after image comparison feature that uses:
- **Native Flutter implementation** for Android, iOS, and Desktop platforms
- **Juxtapose.js via WebView** for Web platform

This hybrid approach ensures optimal performance on native platforms while maintaining full web compatibility.

## License Information

**Juxtapose.js License**: Mozilla Public License 2.0 (MPL-2.0)

Juxtapose.js is licensed under MPL-2.0, which is a weak copyleft license. Key points for integration:

- **Free to use**: Can be used in commercial and non-commercial projects
- **Source code availability**: If you distribute Juxtapose.js in executable form, you must make the source code available
- **Modifications**: Can modify and redistribute under MPL-2.0
- **Compatibility**: Can be distributed under MPL-2.0 or compatible licenses (GPL, LGPL, AGPL)
- **No additional fees**: No licensing fees or royalties required

**Integration Requirements**:
- When using Juxtapose.js in your Flutter web build, you must:
  1. Include the MPL-2.0 license notice
  2. Provide access to Juxtapose.js source code (or link to the original repository)
  3. Preserve copyright and license notices

**For Native Implementation**:
- The native Flutter widget is a custom implementation inspired by Juxtapose.js
- Not a direct copy or derivative work of Juxtapose.js
- Therefore, the native implementation is not subject to MPL-2.0
- Can be licensed under your project's existing license

**Recommended Practice**:
- Add attribution in your app's About or Settings screen: "Before/After comparison feature inspired by JuxtaposeJS by Northwestern University Knight Lab"
- Include Juxtapose.js license in your project's THIRD-PARTY-LICENSES file
- Link to Juxtapose.js repository: https://github.com/NUKnightLab/juxtapose

## Technical Architecture

### Platform Detection Strategy

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional rendering based on platform
Widget build(BuildContext context) {
  if (kIsWeb) {
    return JuxtaposeWebView(beforeImage: ..., afterImage: ...);
  } else {
    return NativeImageComparison(beforeImage: ..., afterImage: ...);
  }
}
```

## Component Architecture

### Directory Structure

```
lib/
├── core/
│   ├── models/
│   │   └── image_comparison.dart          # Comparison state model
│   ├── widgets/
│   │   ├── image_comparison_slider.dart  # Native Flutter widget
│   │   └── juxtapose_web_view.dart        # WebView wrapper for web
│   └── services/
│       └── image_comparison_service.dart  # Business logic
└── screens/
    └── photo_editor/
        └── photo_editor_screen.dart       # Integration point
```

## Implementation Details

### 1. Data Model: ImageComparison

**File**: `lib/core/models/image_comparison.dart`

```dart
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum ComparisonMode {
  slider,      // Drag slider to reveal
  swipe,       // Swipe gesture to toggle
  sideBySide,  // Split view
}

class ImageComparison extends Equatable {
  final String beforeImagePath;
  final String afterImagePath;
  final double sliderPosition; // 0.0 to 1.0
  final ComparisonMode mode;
  final bool showLabels;
  final String beforeLabel;
  final String afterLabel;
  final Color sliderColor;
  final double sliderWidth;

  const ImageComparison({
    required this.beforeImagePath,
    required this.afterImagePath,
    this.sliderPosition = 0.5,
    this.mode = ComparisonMode.slider,
    this.showLabels = true,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.sliderColor = Colors.white,
    this.sliderWidth = 4.0,
  });

  ImageComparison copyWith({
    String? beforeImagePath,
    String? afterImagePath,
    double? sliderPosition,
    ComparisonMode? mode,
    bool? showLabels,
    String? beforeLabel,
    String? afterLabel,
    Color? sliderColor,
    double? sliderWidth,
  }) {
    return ImageComparison(
      beforeImagePath: beforeImagePath ?? this.beforeImagePath,
      afterImagePath: afterImagePath ?? this.afterImagePath,
      sliderPosition: sliderPosition ?? this.sliderPosition,
      mode: mode ?? this.mode,
      showLabels: showLabels ?? this.showLabels,
      beforeLabel: beforeLabel ?? this.beforeLabel,
      afterLabel: afterLabel ?? this.afterLabel,
      sliderColor: sliderColor ?? this.sliderColor,
      sliderWidth: sliderWidth ?? this.sliderWidth,
    );
  }

  @override
  List<Object?> get props => [
        beforeImagePath,
        afterImagePath,
        sliderPosition,
        mode,
        showLabels,
        beforeLabel,
        afterLabel,
        sliderColor,
        sliderWidth,
      ];
}
```

### 2. Native Flutter Widget: ImageComparisonSlider

**File**: `lib/core/widgets/image_comparison_slider.dart`

**Key Features**:
- Stack-based layout with two images
- ClipRect for revealing portions
- GestureDetector for drag interactions
- Animated slider handle
- Optional labels
- Smooth 60fps performance
- Material Design 3 styling

**Technical Approach**:
```dart
class ImageComparisonSlider extends StatefulWidget {
  final ImageComparison comparison;
  final ValueChanged<double>? onSliderChange;
  final double height;
  final bool interactive;

  const ImageComparisonSlider({
    super.key,
    required this.comparison,
    this.onSliderChange,
    this.height = 300,
    this.interactive = true,
  });

  @override
  State<ImageComparisonSlider> createState() => _ImageComparisonSliderState();
}

class _ImageComparisonSliderState extends State<ImageComparisonSlider> {
  double _sliderPosition = 0.5;

  @override
  void initState() {
    super.initState();
    _sliderPosition = widget.comparison.sliderPosition;
  }

  void _updateSlider(double delta) {
    setState(() {
      _sliderPosition = (_sliderPosition + delta).clamp(0.0, 1.0);
    });
    widget.onSliderChange?.call(_sliderPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Stack(
        children: [
          // Before image (bottom layer)
          Positioned.fill(
            child: _buildImage(widget.comparison.beforeImagePath),
          ),
          // After image (top layer, clipped)
          Positioned.fill(
            child: ClipRect(
              clipper: _ImageClipper(_sliderPosition),
              child: _buildImage(widget.comparison.afterImagePath),
            ),
          ),
          // Slider handle
          Positioned(
            left: _sliderPosition * MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            child: _buildSliderHandle(),
          ),
          // Labels (optional)
          if (widget.comparison.showLabels) _buildLabels(),
        ],
      ),
    );
  }
}
```

**Custom Clipper**:
```dart
class _ImageClipper extends CustomClipper<Rect> {
  final double position;

  _ImageClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_ImageClipper oldClipper) {
    return oldClipper.position != position;
  }
}
```

### 3. WebView Widget: JuxtaposeWebView

**File**: `lib/core/widgets/juxtapose_web_view.dart`

**Dependencies**:
- `webview_flutter: ^4.4.2` (already in pubspec.yaml)

**Technical Approach**:
```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JuxtaposeWebView extends StatefulWidget {
  final String beforeImagePath;
  final String afterImagePath;
  final String beforeLabel;
  final String afterLabel;
  final double initialPosition;

  const JuxtaposeWebView({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.initialPosition = 0.5,
  });

  @override
  State<JuxtaposeWebView> createState() => _JuxtaposeWebViewState();
}

class _JuxtaposeWebViewState extends State<JuxtaposeWebView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_generateHtml());
  }

  String _generateHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Image Comparison</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: #000;
    }
    .juxtapose {
      position: relative;
      width: 100%;
      height: 100vh;
    }
    .image-container {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
    }
    .before-image {
      z-index: 1;
    }
    .after-image {
      z-index: 2;
      overflow: hidden;
    }
    .slider {
      position: absolute;
      top: 0;
      bottom: 0;
      width: 4px;
      background: white;
      cursor: ew-resize;
      z-index: 10;
      box-shadow: 0 0 10px rgba(0,0,0,0.5);
    }
    .slider-handle {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 40px;
      height: 40px;
      background: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 2px 10px rgba(0,0,0,0.3);
    }
    .label {
      position: absolute;
      top: 20px;
      padding: 8px 16px;
      background: rgba(0,0,0,0.7);
      color: white;
      font-family: sans-serif;
      font-size: 14px;
      border-radius: 4px;
      z-index: 5;
    }
    .before-label {
      left: 20px;
    }
    .after-label {
      right: 20px;
    }
  </style>
</head>
<body>
  <div class="juxtapose" id="juxtapose">
    <div class="image-container before-image">
      <img src="${widget.beforeImagePath}" style="width: 100%; height: 100%; object-fit: contain;">
      <div class="label before-label">${widget.beforeLabel}</div>
    </div>
    <div class="image-container after-image" id="afterContainer" style="width: ${widget.initialPosition * 100}%">
      <img src="${widget.afterImagePath}" style="width: 100%; height: 100%; object-fit: contain;">
      <div class="label after-label">${widget.afterLabel}</div>
    </div>
    <div class="slider" id="slider" style="left: ${widget.initialPosition * 100}%">
      <div class="slider-handle">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#333" stroke-width="2">
          <path d="M15 18l-6-6 6-6"/>
          <path d="M9 18l6-6-6-6"/>
        </svg>
      </div>
    </div>
  </div>
  <script>
    const slider = document.getElementById('slider');
    const afterContainer = document.getElementById('afterContainer');
    const juxtapose = document.getElementById('juxtapose');
    let isDragging = false;

    function updateSlider(x) {
      const rect = juxtapose.getBoundingClientRect();
      let position = (x - rect.left) / rect.width;
      position = Math.max(0, Math.min(1, position));
      slider.style.left = (position * 100) + '%';
      afterContainer.style.width = (position * 100) + '%';
    }

    slider.addEventListener('mousedown', (e) => {
      isDragging = true;
      e.preventDefault();
    });

    document.addEventListener('mousemove', (e) => {
      if (isDragging) {
        updateSlider(e.clientX);
      }
    });

    document.addEventListener('mouseup', () => {
      isDragging = false;
    });

    // Touch support
    slider.addEventListener('touchstart', (e) => {
      isDragging = true;
      e.preventDefault();
    });

    document.addEventListener('touchmove', (e) => {
      if (isDragging) {
        updateSlider(e.touches[0].clientX);
      }
    });

    document.addEventListener('touchend', () => {
      isDragging = false;
    });
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
```

### 4. Service: ImageComparisonService

**File**: `lib/core/services/image_comparison_service.dart`

```dart
import 'package:flutter/material.dart';
import '../models/image_comparison.dart';

class ImageComparisonService {
  static ImageComparison createDefaultComparison({
    required String beforeImagePath,
    required String afterImagePath,
    String? beforeLabel,
    String? afterLabel,
  }) {
    return ImageComparison(
      beforeImagePath: beforeImagePath,
      afterImagePath: afterImagePath,
      beforeLabel: beforeLabel ?? 'Original',
      afterLabel: afterLabel ?? 'Filtered',
      sliderPosition: 0.5,
      mode: ComparisonMode.slider,
      showLabels: true,
      sliderColor: Colors.white,
      sliderWidth: 4.0,
    );
  }

  static List<Color> getPresetSliderColors() {
    return [
      Colors.white,
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.amber,
    ];
  }

  static List<ComparisonMode> getAvailableModes() {
    return ComparisonMode.values;
  }
}
```

### 5. Integration with PhotoEditorScreen

**File**: `lib/screens/photo_editor/photo_editor_screen.dart`

**Changes Required**:

1. Add state for comparison mode:
```dart
bool _showComparison = false;
```

2. Add comparison button in AppBar:
```dart
AppBar(
  title: Text('Photo Editor'),
  actions: [
    IconButton(
      icon: Icon(Icons.compare),
      tooltip: 'Compare Original',
      onPressed: () {
        setState(() {
          _showComparison = !_showComparison;
        });
      },
    ),
    // ... existing actions
  ],
)
```

3. Replace image preview with comparison widget when enabled:
```dart
Widget _buildImagePreview() {
  if (_showComparison) {
    if (kIsWeb) {
      return JuxtaposeWebView(
        beforeImagePath: widget.imageItem.path,
        afterImagePath: _getFilteredImagePath(),
        beforeLabel: 'Original',
        afterLabel: _currentFilter.toString().split('.').last,
      );
    } else {
      return ImageComparisonSlider(
        comparison: ImageComparisonService.createDefaultComparison(
          beforeImagePath: widget.imageItem.path,
          afterImagePath: _getFilteredImagePath(),
          beforeLabel: 'Original',
          afterLabel: _currentFilter.toString().split('.').last,
        ),
        height: 400,
        interactive: true,
        onSliderChange: (position) {
          // Optional: track slider position
        },
      );
    }
  } else {
    return FilteredImagePreview(
      image: widget.imageItem,
      filter: _currentFilter,
    );
  }
}
```

## UI/UX Design

### Visual Style

**Native Implementation**:
- Material Design 3 color scheme
- Smooth slider handle with arrow icons
- Semi-transparent labels with backdrop blur
- Animated transitions when toggling comparison mode

**Web Implementation**:
- Matches native visual style
- Responsive design for all screen sizes
- Touch-friendly slider handle

### User Flow

1. User opens Photo Editor
2. Applies filter to image
3. Taps "Compare" button in AppBar
4. Slider appears showing original vs filtered
5. User drags slider to reveal different portions
6. User can adjust filter while comparison is active
7. Tap "Compare" again to return to normal view

### Comparison Modes

**Slider Mode** (Default):
- Drag slider left/right to reveal portions
- Most intuitive for before/after comparison

**Swipe Mode** (Future Enhancement):
- Swipe gesture toggles between full images
- Quick comparison of entire images

**Side-by-Side Mode** (Future Enhancement):
- Split screen view
- Good for landscape orientation

## Dependencies

### Required Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Existing
  provider: ^6.1.1
  image_picker: ^1.0.7
  image: ^4.1.7
  equatable: ^2.0.5

  # New for web support
  webview_flutter: ^4.4.2
```

**Note**: `webview_flutter` may already be in pubspec.yaml. Check before adding.

## Performance Considerations

### Native Implementation
- **60fps rendering**: Uses Flutter's Skia engine
- **Memory efficient**: Only loads two images
- **No JavaScript overhead**: Pure Dart code
- **Smooth animations**: Native gesture handling

### Web Implementation
- **WebView overhead**: Slight performance impact
- **JavaScript execution**: Minimal overhead for simple interactions
- **Image loading**: Same as native (cached by browser)

### Optimization Strategies

1. **Image Caching**: Cache filtered images to avoid recomputation
2. **Lazy Loading**: Only load comparison widget when needed
3. **Memory Management**: Dispose controllers properly
4. **Thumbnails**: Use thumbnails for preview, full resolution for export

## Export Functionality

### Export Comparison View

**Option 1: Export as Split Image**
- Capture both sides in single image
- Use RepaintBoundary for high-quality export
- Add divider line

**Option 2: Export as Video**
- Animate slider from left to right
- Use FFmpeg for video generation
- Similar to slideshow export

**Option 3: Export as GIF**
- Animated GIF showing comparison
- Smaller file size than video
- Easy to share

**Implementation** (Future Enhancement):
```dart
Future<void> _exportComparison() async {
  final boundary = GlobalKey();
  final RenderRepaintBoundary renderObject =
      boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await renderObject.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Save using existing export helper
  await _saveImage(bytes, 'comparison.png');
}
```

## Testing Strategy

### Unit Tests
- Test ImageComparison model
- Test ImageComparisonService methods
- Test state management

### Widget Tests
- Test ImageComparisonSlider rendering
- Test slider interaction
- Test label display
- Test mode switching

### Integration Tests
- Test PhotoEditorScreen integration
- Test comparison toggle
- Test export functionality

### Platform-Specific Tests
- Test native implementation on Android/iOS/Desktop
- Test web implementation on Chrome/Safari/Firefox
- Test responsive design on different screen sizes

## Implementation Timeline

### Phase 1: Core Implementation (Priority 1)
1. Create ImageComparison model
2. Implement Native ImageComparisonSlider widget
3. Implement JuxtaposeWebView widget
4. Create ImageComparisonService
5. Integrate with PhotoEditorScreen

### Phase 2: UI Refinement (Priority 2)
1. Add Material Design 3 styling
2. Implement smooth animations
3. Add label customization
4. Add slider color options

### Phase 3: Advanced Features (Priority 3)
1. Add swipe mode
2. Add side-by-side mode
3. Implement export functionality
4. Add keyboard shortcuts

### Phase 4: Polish & Testing (Priority 4)
1. Comprehensive testing
2. Performance optimization
3. Accessibility improvements
4. Documentation

## Future Enhancements

1. **Multiple Comparison Points**: Support for more than 2 images
2. **Animated Transitions**: Smooth fade between comparison modes
3. **Custom Labels**: Allow users to customize labels
4. **Comparison History**: Save comparison snapshots
5. **Share Comparison**: Share comparison as image/video
6. **AI Suggestions**: Suggest optimal filter based on comparison

## Migration Path

### Existing Code Changes

**PhotoEditorScreen**:
- Add comparison toggle button
- Add state management for comparison mode
- Replace image preview with conditional widget

**No Breaking Changes**:
- Existing functionality preserved
- Comparison is opt-in feature
- Backward compatible with existing filters

## Conclusion

This hybrid implementation provides:
- ✅ Optimal performance on native platforms
- ✅ Full web compatibility
- ✅ Consistent user experience across platforms
- ✅ Easy integration with existing codebase
- ✅ Future extensibility
- ✅ No breaking changes

The implementation follows SZ Pic's Clean Architecture pattern and maintains consistency with existing widgets and services.
