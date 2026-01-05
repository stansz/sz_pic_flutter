# Architecture

## Overview

SZ Pic follows **Clean Architecture** principles with a feature-based organization. The architecture separates concerns into three main layers: Presentation (UI), Domain (Business Logic), and Data (Models).

## Directory Structure

```
lib/
├── core/
│   ├── models/           # Data models (immutable, Equatable)
│   │   ├── image_item.dart
│   │   ├── collage_models.dart
│   │   ├── slideshow_models.dart
│   │   └── ai_models.dart
│   └── services/         # Business logic services
│       ├── ai_provider.dart (abstract)
│       ├── ollama_provider.dart
│       ├── openrouter_provider.dart
│       ├── collage_engine.dart
│       └── image_picker_service.dart
├── screens/              # UI screens (stateful/stateless widgets)
│   ├── home_screen.dart
│   └── collage/
│       ├── collage_creator_screen.dart
│       └── collage_editor_screen.dart
└── main.dart             # App entry point (Provider setup)
```

## Core Models

### ImageItem (`lib/core/models/image_item.dart`)
Represents an image with metadata.
- **Properties**: id, path, name, addedAt, width, height, fileSize
- **Features**: Equatable for value equality, JSON serialization
- **Usage**: All images throughout app use this model

### Collage Models (`lib/core/models/collage_models.dart`)

**LayoutType** (Enum)
- grid, masonry, template, freestyle, smart

**LayoutCell**
- Represents a single image position in collage
- Uses normalized coordinates (0-1 range for x, y, width, height)
- Supports rotation (-180 to 180 degrees) and scale
- **Free Crop Support**: Added `imageOffsetX` and `imageOffsetY` properties (normalized -0.5 to 0.5)
  - Allows image repositioning within cell boundaries
  - Independent of cell position/size
  - Used for precise image cropping and positioning
- Each cell can reference an imageId

**CollageLayout**
- Complete layout definition with cells, type, aspectRatio
- backgroundColor (stored asint for Color compatibility)
- spacing and padding in normalized units
- Immutable with copyWith for updates

**CollageProject**
- Full project including layout, images list, timestamps
- name, id, thumbnailPath for project management
- Ready for SQLite serialization

### Slideshow Models (`lib/core/models/slideshow_models.dart`)

**TransitionType** (Enum)
- fade, slide, zoom, dissolve, kenBurns

**Transition Effect**
- Configuration for slide transitions
- duration, type, custom parameters

**Slide**
- Individual slide with image, duration, transitions
- order for sequencing
- inTransition and outTransition

**SlideshowProject**
- Complete slideshow with slides, music, duration
- Similar structure to CollageProject for consistency

### AI Models (`lib/core/models/ai_models.dart`)

**AIProviderType** (Enum)
- ollama, openRouter

**AIProviderConfig**
- baseUrl, apiKey, model name
- additionalParams for flexibility
- Factory methods: defaultOllama(), defaultOpenRouter()

**RecommendationType** (Enum)
- collageLayout, colorScheme, imageEnhancement, filterSuggestion, compositionAnalysis

**AIRecommendation**
- Generic recommendation structure
- title, description, confidence score
- data payload as Map<String, dynamic>
- generatedAt timestamp

**LayoutSuggestionRequest/Response**
- Request: imageCount, theme, style, aspectRatio
- Response: list of AIRecommendation, reasoning text

## Core Services

### AI Provider Architecture

**Abstract Interface** (`lib/core/services/ai_provider.dart`)
```dart
abstract class AIProvider {
  AIProviderConfig get config;
  Future<bool> isAvailable();
  Future<LayoutSuggestionResponse> getLayoutSuggestions(LayoutSuggestionRequest);
  Future<List<AIRecommendation>> getColorSchemeRecommendations(List<String> imagePaths);
  Future<String> generateRecommendation(String prompt);
}
```

**Ollama Provider** (`lib/core/services/ollama_provider.dart`)
- Implements AIProvider
- Uses Dio HTTP client
- POST to `/api/generate` endpoint
- Prompt engineering for layout and color suggestions
- Regex-based JSON extraction with fallback handling
- Default: `http://localhost:11434`, model: `llama3.2-vision`

**OpenRouter Provider** (`lib/core/services/openrouter_provider.dart`)
- Implements AIProvider
- Uses Dio with Bearer authentication
- POST to `/api/v1/chat/completions`
- Messages array format (OpenAI-compatible)
- Default model: `anthropic/claude-3.5-sonnet`

### Collage Engine (`lib/core/services/collage_engine.dart`)

**Layout Algorithms**:

1. **Grid Layout** (`createGridLayout`)
   - Calculates optimal columns: `sqrt(imageCount).ceil()`
   - Evenly distributes cells
   - Respects spacing and padding

2. **Masonry Layout** (`createMasonryLayout`)
   - Pinterest-style cascading
   - Tracks column heights
   - Random cell heights (0.8-1.4 * width)
   - Places in shortest column

3. **Template Layout** (`createTemplateLayout`)
   - Pre-designed attractive layouts for 2-5 images
   - Switch case by image count
   - Hardcoded professional arrangements
   - Falls back to grid for 6+ images

4. **Freestyle Layout** (`createFreestyleLayout`)
   - Random positioning within bounds
   - Cell size: 20-40% of canvas
   - Rotation: -15 to +15 degrees
   - Ensures cells fit in padded area

**Utility Methods**:
- `assignImagesToLayout()`: Maps image IDs to cells
- `updateCell()`: Immutably updates single cell

### Image Picker Service (`lib/core/services/image_picker_service.dart`)

- **Single Image**: `pickImage(ImageSource source)`
- **Multiple Images**: `pickMultipleImages()`
- **Camera**: `takePhoto()`
- Extracts metadata using `image` package
- Creates ImageItem with UUID, dimensions, file size
- Returns List<ImageItem> for easy integration

## State Management

**Provider Pattern** used throughout:

**Setup** (`lib/main.dart`):
```dart
MultiProvider(
  providers: [
    Provider<ImagePickerService>(create: (_) => ImagePickerService()),
    Provider<CollageEngine>(create: (_) => CollageEngine()),
    Provider<AIProvider>(create: (_) => OllamaProvider(config: ...)),
  ],
  child: MaterialApp(...)
)
```

**Usage in Widgets**:
```dart
// Read once
final engine = context.read<CollageEngine>();

// Listen to changes (if provider is ChangeNotifier)
final engine = context.watch<CollageEngine>();

// Without rebuild
Provider.of<ImagePickerService>(context, listen: false)
```

## Screens Architecture

### HomeScreen (`lib/screens/home_screen.dart`)
- Entry point after app launch
- 4 navigation cards: Create Collage, Create Slideshow, My Projects, Settings
- Gradient background
- Handles image picker service calls
- Navigates to CollageCreatorScreen with images

### CollageCreatorScreen (`lib/screens/collage/collage_creator_screen.dart`)
- Receives List<ImageItem> from navigation
- Generates 4 default layouts on init
- Shows visual previews using CustomPainter
- "AI Suggestions" button for additional layouts
- Error handling with colored containers
- Tapping layout navigates to CollageEditorScreen

### CollageEditorScreen (`lib/screens/collage/collage_editor_screen.dart`)
- Receives CollageLayout and List<ImageItem>
- Uses RepaintBoundary for export capability
- Stack-based rendering with Positioned cells
- Transform.rotate and Transform.scale for effects
- Bottom controls: Aspect, Spacing, Shuffle, AI Enhance
- Export uses `RenderRepaintBoundary.toImage(pixelRatio: 3.0)`
- Saves to application documents directory

## Key Technical Patterns

### Normalized Coordinates
All layout positions use 0-1 range:
- **x, y**: Position as fraction of canvas (0 = left/top, 1 = right/bottom)
- **width, height**: Size as fraction of canvas
- **Benefits**: Resolution-independent, easy scaling

### Immutable Models with copyWith
```dart
final updatedLayout = layout.copyWith(
  backgroundColor: newColor,
  cells: newCells,
);
```

### Equatable for Value Equality
All models extend Equatable:
```dart
class ImageItem extends Equatable {
  @override
  List<Object?> get props => [id, path, name, ...];
}
```

### Dependency Injection via Provider
Services injected at app root, accessed anywhere via context

### Separation of Concerns
- Models: Pure data classes
- Services: Business logic, no UI
- Screens: UI only, delegates to services

## Data Flow

1. User Action → Screen
2. Screen calls Service (via Provider)
3. Service processes and returns Models
4. Screen updates State
5. Widget tree rebuilds

Example: Creating Collage
```
HomeScreen.pickImages()
  → ImagePickerService.pickMultipleImages()
  → returns List<ImageItem>
  → navigate to CollageCreatorScreen(images)
  → CollageEngine.createGridLayout(imageCount)
  → returns CollageLayout
  → display preview
  → user selects → navigate to CollageEditorScreen
  → user edits/exports
```

## Testing Strategy (Planned)

- **Unit Tests**: Models, Services (pure logic)
- **Widget Tests**: Individual screens
- **Integration Tests**: Complete user flows
- **Golden Tests**: UI consistency

## Performance Considerations

1. **Image Loading**: Use `Image.file()` with caching
2. **Layout Generation**: All synchronous, sub-millisecond
3. **AI Calls**: Async with loading states, timeouts
4. **Export**: Background thread via compute() if needed
5. **Memory**: Dispose controllers, limit cached images

## Future Architecture Improvements

1. **Repository Pattern**: Abstract storage layer
2. **Use Cases/Interactors**: Complex business logic
3. **BLoC/Riverpod**: More structured state management
4. **Dependency Injection Container**: Get_it or Injectable
5. **Error Handling Middleware**: Centralized error processing
6. **Analytics Service**: Track usage patterns
7. **Offline Support**: Queue exports, sync when online
