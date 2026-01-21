# Auto-Save System with Drafts - Architecture Plan

## Overview

Implement an automatic draft saving system that preserves user work across sessions, with a "Recent Projects" section on the home screen for quick resumption of work.

## Goals

1. **Automatic Saving**: Save work automatically every 30 seconds of inactivity or on critical changes
2. **Recent Projects**: Display saved drafts on HomeScreen with thumbnails
3. **Quick Resumption**: One-tap to continue editing from any draft
4. **Cross-Platform**: Support Android, iOS, and web (with fallback)
5. **Clean Management**: Auto-cleanup old drafts (optional, configurable)

## System Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Auto-Save System                          │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Project    │    │  AutoSave    │    │  Thumbnail   │
│  Repository  │    │   Service    │    │  Generator   │
└──────────────┘    └──────────────┘    └──────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   SQLite    │    │   Timer     │    │RepaintBound  │
│  Database   │    │  Debouncer   │    │    ary       │
└──────────────┘    └──────────────┘    └──────────────┘
```

## Data Models

### 1. ProjectType Enum
```dart
enum ProjectType {
  collage,
  slideshow,
  photo,
}
```

### 2. Project Model (Unified)
```dart
class Project extends Equatable {
  final String id;
  final String name;
  final ProjectType type;
  final Map<String, dynamic> data; // Stores CollageProject, SlideshowProject, or PhotoEditData
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final bool isDraft; // true = auto-saved draft, false = manually saved
  final int? autoSaveVersion; // Incremented on each auto-save

  // JSON serialization for SQLite storage
  Map<String, dynamic> toJson();
  factory Project.fromJson(Map<String, dynamic> json);
}
```

### 3. PhotoEditData Model (New)
```dart
class PhotoEditData extends Equatable {
  final String imageId;
  final String imagePath;
  final PhotoFilter filter;
  final Map<String, dynamic>? comparisonSettings;

  Map<String, dynamic> toJson();
  factory PhotoEditData.fromJson(Map<String, dynamic> json);
}
```

## Database Schema (SQLite)

### projects table
```sql
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'collage', 'slideshow', 'photo'
  data TEXT NOT NULL, -- JSON string of project data
  created_at INTEGER NOT NULL, -- Unix timestamp
  updated_at INTEGER NOT NULL, -- Unix timestamp
  thumbnail_path TEXT,
  is_draft INTEGER NOT NULL DEFAULT 1, -- 0 = saved, 1 = draft
  auto_save_version INTEGER DEFAULT 0
);

CREATE INDEX idx_projects_type ON projects(type);
CREATE INDEX idx_projects_updated ON projects(updated_at DESC);
CREATE INDEX idx_projects_draft ON projects(is_draft, updated_at DESC);
```

## Core Services

### 1. ProjectRepository Service
**Location**: `lib/core/services/project_repository.dart`

**Responsibilities**:
- Initialize SQLite database
- CRUD operations for projects
- Query operations (by type, by date, drafts only)
- Thumbnail path management
- Auto-cleanup of old drafts

**Key Methods**:
```dart
class ProjectRepository {
  Future<void> initialize();
  Future<String> saveProject(Project project);
  Future<Project?> getProject(String id);
  Future<List<Project>> getAllProjects();
  Future<List<Project>> getProjectsByType(ProjectType type);
  Future<List<Project>> getDrafts();
  Future<void> deleteProject(String id);
  Future<void> deleteOldDrafts({Duration olderThan = const Duration(days: 7)});
  Future<String> saveThumbnail(String projectId, Uint8List thumbnailBytes);
}
```

**Implementation Details**:
- Use `sqflite` package (already in pubspec.yaml)
- Database location: `getApplicationDocumentsDirectory()/sz_pic_projects.db`
- Store project data as JSON string in TEXT column
- Thumbnails stored as files in `thumbnails/` subdirectory
- Use transactions for atomic operations

### 2. AutoSaveService Service
**Location**: `lib/core/services/auto_save_service.dart`

**Responsibilities**:
- Monitor editor state changes
- Debounce save operations (30 seconds after last change)
- Track active project ID
- Provide save callbacks to editors

**Key Methods**:
```dart
class AutoSaveService extends ChangeNotifier {
  String? activeProjectId;
  ProjectType? activeProjectType;
  Timer? _autoSaveTimer;
  Duration autoSaveDelay = const Duration(seconds: 30);

  void startAutoSave({
    required String projectId,
    required ProjectType type,
    required Future<void> Function() saveCallback,
  });

  void triggerSave(); // Manual trigger or timer callback
  void stopAutoSave();
  void resetTimer(); // Called on any change
}
```

**Implementation Details**:
- Use `Timer` for debouncing
- Reset timer on any user interaction (drag, resize, filter change, etc.)
- Auto-save on app lifecycle events (paused, inactive)
- Notify listeners on save completion

### 3. ThumbnailGenerator Service
**Location**: `lib/core/services/thumbnail_generator.dart`

**Responsibilities**:
- Generate thumbnails from project previews
- Save thumbnails to file system
- Return thumbnail paths

**Key Methods**:
```dart
class ThumbnailGenerator {
  static Future<String> generateCollageThumbnail(
    CollageLayout layout,
    List<ImageItem> images,
    String projectId,
  );

  static Future<String> generateSlideshowThumbnail(
    SlideshowProject project,
    String projectId,
  );

  static Future<String> generatePhotoThumbnail(
    ImageItem image,
    PhotoFilter filter,
    String projectId,
  );

  static Future<String> _captureWidget(
    Widget widget,
    String projectId,
  );
}
```

**Implementation Details**:
- Use `RepaintBoundary` widget to capture preview
- Render at 200x200 resolution for thumbnails
- Save as PNG to `thumbnails/{projectId}.png`
- Use `compute()` for off-thread generation if needed

## UI Components

### 1. RecentProjectsWidget
**Location**: `lib/core/widgets/recent_projects_widget.dart`

**Features**:
- Horizontal scrollable list of recent projects
- Display thumbnail, name, and "Edited X hours ago"
- Tap to load project
- Long-press for options (delete, rename)
- Empty state: "No recent projects"

**Layout**:
```
┌─────────────────────────────────────────────────────────┐
│ Recent Projects                                      │
├─────────────────────────────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│ │ IMG │ │ IMG │ │ IMG │ │ IMG │ │ IMG │   │
│ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘   │
│ Collage  Slideshow  Photo  Collage  Slideshow      │
│ 2h ago    5h ago   1d ago  2d ago   3d ago   │
└─────────────────────────────────────────────────────────┘
```

### 2. ProjectCard Widget
**Location**: `lib/core/widgets/project_card.dart`

**Features**:
- Project thumbnail (cached image)
- Project name with truncation
- Type badge (Collage/Slideshow/Photo)
- Last edited timestamp
- Draft indicator (if isDraft)
- Tap to edit, long-press for menu

## Integration Points

### HomeScreen Integration

**Changes to `lib/screens/home_screen.dart`**:

1. Add RecentProjectsWidget below header
2. Listen to ProjectRepository for updates
3. Handle project tap navigation
4. Show loading state for project loading

```dart
class _HomeScreenState extends State<HomeScreen> {
  List<Project> _recentProjects = [];

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
  }

  Future<void> _loadRecentProjects() async {
    final repo = context.read<ProjectRepository>();
    final projects = await repo.getDrafts();
    if (mounted) {
      setState(() {
        _recentProjects = projects.take(10).toList();
      });
    }
  }

  void _onProjectTap(Project project) {
    // Navigate to appropriate editor based on project.type
    switch (project.type) {
      case ProjectType.collage:
        Navigator.push(..., CollageEditorScreen.fromProject(project));
        break;
      case ProjectType.slideshow:
        Navigator.push(..., SlideshowEditorScreen.fromProject(project));
        break;
      case ProjectType.photo:
        Navigator.push(..., PhotoEditorScreen.fromProject(project));
        break;
    }
  }
}
```

### Editor Screen Integration

**Pattern for all editors**:

1. Initialize AutoSaveService on screen load
2. Call `resetTimer()` on any user interaction
3. Provide save callback that serializes current state
4. Stop AutoSaveService on dispose
5. Navigate back to HomeScreen on save completion

**Example - CollageEditorScreen**:

```dart
class _CollageEditorScreenState extends State<CollageEditorScreen> {
  String? _projectId;
  late AutoSaveService _autoSaveService;

  @override
  void initState() {
    super.initState();
    _projectId = widget.projectId ?? const Uuid().v4();
    _autoSaveService = context.read<AutoSaveService>();

    // Start auto-save
    _autoSaveService.startAutoSave(
      projectId: _projectId!,
      type: ProjectType.collage,
      saveCallback: _saveCurrentState,
    );
  }

  Future<void> _saveCurrentState() async {
    final repo = context.read<ProjectRepository>();
    final project = Project(
      id: _projectId!,
      name: 'Collage ${DateTime.now().toString().substring(0, 10)}',
      type: ProjectType.collage,
      data: {
        'layout': _layout.toJson(),
        'images': _images.map((img) => img.toJson()).toList(),
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDraft: true,
    );

    // Generate thumbnail
    final thumbnailPath = await ThumbnailGenerator.generateCollageThumbnail(
      _layout,
      _images,
      _projectId!,
    );

    await repo.saveProject(project.copyWith(thumbnailPath: thumbnailPath));
  }

  @override
  void dispose() {
    _autoSaveService.stopAutoSave();
    super.dispose();
  }

  // Call this on any user interaction
  void _onUserInteraction() {
    _autoSaveService.resetTimer();
  }
}
```

## File Structure

```
lib/
├── core/
│   ├── models/
│   │   ├── project.dart              # NEW: Unified project model
│   │   ├── photo_edit_data.dart       # NEW: Photo editor state
│   │   ├── collage_models.dart       # EXISTING
│   │   ├── slideshow_models.dart    # EXISTING
│   │   └── image_item.dart         # EXISTING
│   ├── services/
│   │   ├── project_repository.dart    # NEW: SQLite CRUD operations
│   │   ├── auto_save_service.dart   # NEW: Auto-save timer & logic
│   │   ├── thumbnail_generator.dart # NEW: Thumbnail generation
│   │   ├── collage_engine.dart      # EXISTING
│   │   ├── slideshow_engine.dart    # EXISTING
│   │   └── ...
│   └── widgets/
│       ├── recent_projects_widget.dart # NEW: Recent projects list
│       ├── project_card.dart         # NEW: Individual project card
│       └── ...
├── screens/
│   ├── home_screen.dart             # MODIFY: Add recent projects
│   ├── collage/
│   │   ├── collage_editor_screen.dart      # MODIFY: Add auto-save
│   │   ├── freestyle_editor_screen.dart   # MODIFY: Add auto-save
│   │   └── ...
│   ├── slideshow/
│   │   └── slideshow_editor_screen.dart   # MODIFY: Add auto-save
│   └── photo_editor/
│       └── photo_editor_screen.dart       # MODIFY: Add auto-save
└── main.dart                           # MODIFY: Add ProjectRepository, AutoSaveService
```

## Implementation Sequence

### Phase 1: Foundation (Core Services)
1. Create `Project` model with JSON serialization
2. Create `PhotoEditData` model
3. Implement `ProjectRepository` with SQLite
4. Create database initialization and schema
5. Test basic CRUD operations

### Phase 2: Auto-Save Logic
1. Implement `AutoSaveService` with timer debouncing
2. Add to Provider in main.dart
3. Test timer behavior and callbacks

### Phase 3: Thumbnail Generation
1. Implement `ThumbnailGenerator` service
2. Create widget capture logic using RepaintBoundary
3. Test thumbnail generation for all project types
4. Verify file storage and retrieval

### Phase 4: UI Components
1. Create `ProjectCard` widget
2. Create `RecentProjectsWidget` with horizontal scroll
3. Add empty state handling
4. Style with Material Design 3

### Phase 5: HomeScreen Integration
1. Add `RecentProjectsWidget` to HomeScreen
2. Load recent projects on init
3. Handle project tap navigation
4. Add loading and error states

### Phase 6: Editor Integration
1. Integrate auto-save into CollageEditorScreen
2. Integrate auto-save into FreestyleEditorScreen
3. Integrate auto-save into SlideshowEditorScreen
4. Integrate auto-save into PhotoEditorScreen
5. Add "resetTimer()" calls on user interactions

### Phase 7: Project Loading
1. Add factory constructors to editor screens
2. Implement project data deserialization
3. Restore editor state from saved data
4. Test loading and editing workflow

### Phase 8: Draft Management
1. Implement old draft cleanup in ProjectRepository
2. Add "Clear All Drafts" option to HomeScreen
3. Add delete confirmation dialogs
4. Test cleanup logic

## Technical Considerations

### Performance
- Use `compute()` for thumbnail generation (off main thread)
- Debounce saves to avoid excessive database writes
- Lazy load thumbnails in RecentProjectsWidget
- Cache thumbnails using `cached_network_image` pattern

### Memory Management
- Dispose AutoSaveService timers properly
- Clean up thumbnail files when projects deleted
- Limit recent projects to 20 items
- Use `Uint8List` for thumbnail bytes (not base64 strings)

### Error Handling
- Wrap all database operations in try-catch
- Show user-friendly error messages
- Fallback to in-memory storage if SQLite fails
- Log errors for debugging

### Platform Differences
- **Web**: Use `shared_preferences` instead of SQLite (no file system)
- **Native**: Use SQLite with file storage
- **Thumbnails**: Store as files (native) or base64 strings (web)

### Data Migration
- Version database schema for future migrations
- Handle model changes gracefully
- Provide upgrade path if needed

## Testing Strategy

### Unit Tests
- Project model JSON serialization/deserialization
- ProjectRepository CRUD operations
- AutoSaveService timer behavior
- ThumbnailGenerator widget capture

### Widget Tests
- ProjectCard display and interactions
- RecentProjectsWidget scrolling and loading
- HomeScreen integration

### Integration Tests
- Complete workflow: Create → Auto-save → Navigate away → Return → Load
- Multiple project types
- Draft cleanup
- Thumbnail generation

## Future Enhancements

1. **Cloud Sync**: Sync drafts across devices
2. **Project Sharing**: Share draft files with other users
3. **Version History**: Keep multiple versions of projects
4. **Auto-Export**: Automatically export final versions
5. **Smart Naming**: AI-generated project names based on content
6. **Project Folders**: Organize projects into collections
7. **Search**: Search saved projects by name or date
8. **Tags**: Add custom tags to projects

## Dependencies

### Already Available
- `sqflite ^2.3.2`: SQLite database
- `path_provider ^2.1.2`: File system paths
- `shared_preferences ^2.2.2`: Simple key-value storage (web fallback)
- `uuid ^4.3.3`: Unique ID generation
- `equatable ^2.0.5`: Value equality

### No New Dependencies Required
All required packages are already in pubspec.yaml

## Success Criteria

- [ ] Projects auto-save every 30 seconds of inactivity
- [ ] Recent projects display on HomeScreen with thumbnails
- [ ] Tapping a project loads it into the appropriate editor
- [ ] Editor state is fully restored from saved data
- [ ] Thumbnails are generated and cached efficiently
- [ ] Old drafts are cleaned up automatically
- [ ] Works on Android, iOS, and web
- [ ] No performance degradation during editing
- [ ] Error handling is robust and user-friendly

## Notes

- Auto-save should not interrupt user flow
- Thumbnails should be generated asynchronously
- Database operations should use transactions
- Consider adding a "Save As" button for permanent saves
- Drafts should be clearly distinguished from saved projects
