# SZ Pic - Implementation Guide

## Getting Started

This guide provides step-by-step instructions for implementing the SZ Pic collage and slideshow application.

## Migration from Kotlin to Flutter

Since the current project is a Kotlin Android project, we'll need to either:

**Option 1: Create New Flutter Project (Recommended)**
- Create a new Flutter project alongside the current Kotlin project
- Migrate gradually or start fresh with Flutter
- Keep the current project as reference

**Option 2: Replace Current Project**
- Archive the current Kotlin project
- Initialize Flutter in the same directory
- Start with clean Flutter structure

## Prerequisites

### Install Required Tools

1. **Flutter SDK**
   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   # Add to PATH
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Verify Installation**
   ```bash
   flutter doctor
   ```

3. **Android Setup**
   ```bash
   flutter doctor --android-licenses
   ```

## Project Setup

### Step 1: Create Flutter Project

```bash
# Navigate to parent directory
cd /Users/sz/StudioProjects

# Create new Flutter project
flutter create sz_pic_flutter

# Or create with specific options
flutter create --org com.szpic --project-name sz_pic_flutter sz_pic_flutter

cd sz_pic_flutter
```

### Step 2: Configure pubspec.yaml

```yaml
name: sz_pic
description: AI-powered collage and slideshow creator
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.1
  
  # Image Handling
  image_picker: ^1.0.5
  image: ^4.1.3
  photo_view: ^0.14.0
  image_cropper: ^5.0.1
  cached_network_image: ^3.3.0
  
  # Storage
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  flutter_secure_storage: ^9.0.0
  
  # Network
  dio: ^5.4.0
  http: ^1.1.2
  
  # UI Components
  flutter_staggered_grid_view: ^0.7.0
  carousel_slider: ^4.2.1
  flutter_colorpicker: ^1.0.3
  dotted_border: ^2.1.0
  
  # Export & Sharing
  share_plus: ^7.2.1
  video_player: ^2.8.1
  ffmpeg_kit_flutter: ^6.0.3
  
  # Utilities
  uuid: ^4.2.1
  intl: ^0.18.1
  path: ^1.8.3
  equatable: ^2.0.5
  
  # JSON
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  json_serializable: ^6.7.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/templates/
    - assets/icons/
```

### Step 3: Update Android Configuration

**android/app/build.gradle**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.szpic.sz_pic"
        minSdkVersion 24  // Android 7.0 for better compatibility
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
        multiDexEnabled true
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
```

**android/app/src/main/AndroidManifest.xml**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.CAMERA" />
    
    <application
        android:label="SZ Pic"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">
        <!-- Activities -->
    </application>
</manifest>
```

## Implementation Phases

### Phase 1: Foundation (Week 1-2)

#### 1.1 Project Structure Setup

Create the folder structure:
```bash
mkdir -p lib/core/{constants,network,storage,utils,widgets}
mkdir -p lib/features/{home,collage,slideshow,ai_recommendations,settings}/{data,domain,presentation}
mkdir -p lib/features/collage/{data/{models,repositories},domain/{entities,usecases},presentation/{screens,widgets,providers}}
mkdir -p lib/features/slideshow/{data/{models,repositories},domain/{entities,usecases},presentation/{screens,widgets,providers}}
mkdir -p lib/features/ai_recommendations/{data/{models,datasources,repositories},domain/{entities,usecases},presentation/{widgets,providers}}
mkdir -p assets/{images,templates,icons}
```

#### 1.2 Core Constants & Configuration

**lib/core/constants/app_constants.dart**
```dart
class AppConstants {
  // App Info
  static const String appName = 'SZ Pic';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String keyAIProvider = 'ai_provider';
  static const String keyOllamaUrl = 'ollama_url';
  static const String keyOpenRouterKey = 'openrouter_key';
  static const String keySelectedModel = 'selected_model';
  
  // AI Defaults
  static const String defaultOllamaUrl = 'http://localhost:11434';
  static const String defaultModel = 'llava';
  
  // Export Settings
  static const int defaultImageQuality = 95;
  static const int maxImageDimension = 4096;
  
  // UI Constants
  static const double collageMinZoom = 0.5;
  static const double collageMaxZoom = 3.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}
```

**lib/core/constants/layout_templates.dart**
```dart
enum LayoutType {
  grid,
  masonry,
  template,
  freestyle,
  smart
}

class LayoutTemplates {
  static List<CollageTemplate> getTemplates() {
    return [
      CollageTemplate(
        id: 'grid_2x2',
        name: '2x2 Grid',
        type: LayoutType.grid,
        rows: 2,
        columns: 2,
      ),
      CollageTemplate(
        id: 'grid_3x3',
        name: '3x3 Grid',
        type: LayoutType.grid,
        rows: 3,
        columns: 3,
      ),
      // Add more templates
    ];
  }
}
```

#### 1.3 Base Data Models

**lib/features/collage/data/models/image_item.dart**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'image_item.g.dart';

@JsonSerializable()
class ImageItem {
  final String id;
  final String path;
  final ImageSource source;
  final DateTime added;
  final ImageMetadata metadata;
  
  ImageItem({
    required this.id,
    required this.path,
    required this.source,
    required this.added,
    required this.metadata,
  });
  
  factory ImageItem.fromJson(Map<String, dynamic> json) => 
      _$ImageItemFromJson(json);
  Map<String, dynamic> toJson() => _$ImageItemToJson(this);
}

@JsonSerializable()
class ImageMetadata {
  final int width;
  final int height;
  final double aspectRatio;
  final int fileSize;
  
  ImageMetadata({
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.fileSize,
  });
  
  factory ImageMetadata.fromJson(Map<String, dynamic> json) => 
      _$ImageMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$ImageMetadataToJson(this);
}

enum ImageSource { gallery, camera, url }
```

#### 1.4 Main App Entry

**lib/main.dart**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        // Add providers here as they're created
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SZ Pic',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

#### 1.5 Home Screen Scaffold

**lib/features/home/presentation/screens/home_screen.dart**
```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SZ Pic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            const Text(
              'Create Beautiful Memories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-powered collages and slideshows',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Quick Actions
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ActionCard(
                    icon: Icons.grid_on,
                    title: 'Create Collage',
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to collage creator
                    },
                  ),
                  _ActionCard(
                    icon: Icons.slideshow,
                    title: 'Create Slideshow',
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to slideshow creator
                    },
                  ),
                  _ActionCard(
                    icon: Icons.folder,
                    title: 'My Projects',
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to projects
                    },
                  ),
                  _ActionCard(
                    icon: Icons.auto_awesome,
                    title: 'AI Studio',
                    color: Colors.green,
                    onTap: () {
                      // Navigate to AI features
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Phase 2: Image Selection & Basic Collage (Week 3-4)

#### 2.1 Image Picker Service

**lib/core/utils/image_picker_service.dart**
```dart
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../models/image_item.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  
  Future<List<ImageItem>> pickMultipleImages() async {
    final List<XFile> files = await _picker.pickMultiImage();
    return _processFiles(files, ImageSource.gallery);
  }
  
  Future<ImageItem?> pickSingleImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final items = await _processFiles([file], ImageSource.gallery);
    return items.firstOrNull;
  }
  
  Future<ImageItem?> takePicture() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    final items = await _processFiles([file], ImageSource.camera);
    return items.firstOrNull;
  }
  
  Future<List<ImageItem>> _processFiles(
    List<XFile> files, 
    ImageSource source
  ) async {
    List<ImageItem> items = [];
    
    for (final file in files) {
      // Read image to get metadata
      final bytes = await File(file.path).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        final metadata = ImageMetadata(
          width: image.width,
          height: image.height,
          aspectRatio: image.width / image.height,
          fileSize: bytes.length,
        );
        
        items.add(ImageItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: file.path,
          source: source,
          added: DateTime.now(),
          metadata: metadata,
        ));
      }
    }
    
    return items;
  }
}
```

#### 2.2 Simple Grid Collage Layout

**lib/features/collage/domain/usecases/create_grid_layout.dart**
```dart
import '../models/collage_layout.dart';

class CreateGridLayout {
  CollageLayout execute({
    required int imageCount,
    int? preferredColumns,
  }) {
    // Calculate optimal grid dimensions
    int columns = preferredColumns ?? _calculateOptimalColumns(imageCount);
    int rows = (imageCount / columns).ceil();
    
    List<LayoutCell> cells = [];
    double cellWidth = 1.0 / columns;
    double cellHeight = 1.0 / rows;
    
    for (int i = 0; i < imageCount; i++) {
      int row = i ~/ columns;
      int col = i % columns;
      
      cells.add(LayoutCell(
        bounds: Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        ),
        imageId: null,
        fit: BoxFit.cover,
      ));
    }
    
    return CollageLayout(
      id: 'grid_${columns}x$rows',
      name: 'Grid $columns×$rows',
      type: LayoutType.grid,
      cells: cells,
    );
  }
  
  int _calculateOptimalColumns(int imageCount) {
    if (imageCount <= 1) return 1;
    if (imageCount <= 4) return 2;
    if (imageCount <= 9) return 3;
    return 4;
  }
}
```

### Phase 3: AI Integration (Week 5-6)

#### 3.1 AI Service Setup

**lib/features/ai_recommendations/data/datasources/ollama_datasource.dart**
```dart
import 'package:dio/dio.dart';

class OllamaDatasource {
  final Dio _dio;
  final String baseUrl;
  
  OllamaDatasource({
    required this.baseUrl,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));
  
  Future<Map<String, dynamic>> chat({
    required String model,
    required String prompt,
    List<String>? imageBase64,
  }) async {
    try {
      final response = await _dio.post(
        '/api/chat',
        data: {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
              if (imageBase64 != null) 'images': imageBase64,
            }
          ],
          'stream': false,
          'format': 'json',
        },
      );
      
      return response.data;
    } catch (e) {
      throw Exception('Ollama request failed: $e');
    }
  }
  
  Future<List<String>> listModels() async {
    final response = await _dio.get('/api/tags');
    final models = response.data['models'] as List;
    return models.map((m) => m['name'] as String).toList();
  }
}
```

**lib/features/ai_recommendations/data/datasources/openrouter_datasource.dart**
```dart
import 'package:dio/dio.dart';

class OpenRouterDatasource {
  final Dio _dio;
  final String apiKey;
  static const String baseUrl = 'https://openrouter.ai/api/v1';
  
  OpenRouterDatasource({
    required this.apiKey,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));
  
  Future<Map<String, dynamic>> chat({
    required String model,
    required String prompt,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'com.szpic.sz_pic',
            'X-Title': 'SZ Pic',
          },
        ),
        data: {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                if (imageUrls != null)
                  ...imageUrls.map((url) => {
                        'type': 'image_url',
                        'image_url': {'url': url},
                      }),
              ],
            }
          ],
          'response_format': {'type': 'json_object'},
        },
      );
      
      return response.data;
    } catch (e) {
      throw Exception('OpenRouter request failed: $e');
    }
  }
}
```

#### 3.2 AI Prompt Builder

**lib/features/ai_recommendations/domain/usecases/get_layout_suggestions.dart**
```dart
class GetLayoutSuggestions {
  final AIRepository _repository;
  
  GetLayoutSuggestions(this._repository);
  
  Future<List<LayoutRecommendation>> execute({
    required List<ImageItem> images,
    String? theme,
    String? mood,
  }) async {
    final prompt = _buildPrompt(images, theme, mood);
    final response = await _repository.getLayoutSuggestions(prompt);
    return _parseResponse(response);
  }
  
  String _buildPrompt(
    List<ImageItem> images, 
    String? theme, 
    String? mood
  ) {
    final aspectRatios = images
        .map((img) => img.metadata.aspectRatio.toStringAsFixed(2))
        .toList();
    
    return '''
You are a professional photo collage designer. Analyze these images and suggest creative collage layouts.

Image Information:
- Count: ${images.length}
- Aspect Ratios: ${aspectRatios.join(', ')}
${theme != null ? '- Theme: $theme' : ''}
${mood != null ? '- Mood: $mood' : ''}

Please suggest 3-5 collage layout arrangements that would:
1. Create visual harmony and balance
2. Highlight important elements
3. Work well for the given aspect ratios
4. Match the theme/mood if specified

Return as JSON with this structure:
{
  "layouts": [
    {
      "name": "Layout name",
      "description": "Why this layout works",
      "type": "grid|masonry|freestyle",
      "cells": [
        {
          "x": 0.0,
          "y": 0.0,
          "width": 0.5,
          "height": 0.5,
          "imageIndex": 0
        }
      ],
      "confidence": 0.95
    }
  ]
}

All position and size values should be normalized (0.0 to 1.0).
''';
  }
  
  List<LayoutRecommendation> _parseResponse(Map<String, dynamic> response) {
    // Parse JSON response into LayoutRecommendation objects
    // Implementation details...
    return [];
  }
}
```

### Phase 4: Testing & Polish (Week 7-8)

#### 4.1 Unit Tests Example

**test/features/collage/domain/usecases/create_grid_layout_test.dart**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sz_pic/features/collage/domain/usecases/create_grid_layout.dart';

void main() {
  late CreateGridLayout usecase;
  
  setUp(() {
    usecase = CreateGridLayout();
  });
  
  test('should create 2x2 grid for 4 images', () {
    final layout = usecase.execute(imageCount: 4);
    
    expect(layout.cells.length, 4);
    expect(layout.name, contains('2×2'));
  });
  
  test('should create 3x3 grid for 9 images', () {
    final layout = usecase.execute(imageCount: 9);
    
    expect(layout.cells.length, 9);
    expect(layout.name, contains('3×3'));
  });
}
```

## Running the App

### Development
```bash
# Run on connected device/emulator
flutter run

# Run with specific device
flutter devices
flutter run -d <device-id>

# Hot reload (while running)
# Press 'r' in terminal or use IDE hot reload
```

### Build
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Build for specific architecture
flutter build apk --split-per-abi
```

## Debugging

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Logs
```bash
flutter logs
```

## Next Steps

1. **Week 1-2**: Set up Flutter project, basic UI, image selection
2. **Week 3-4**: Collage engine, slideshow basics, export
3. **Week 5-6**: AI integration (Ollama + OpenRouter)
4. **Week 7-8**: Polish, testing, documentation

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Ollama API Reference](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [OpenRouter API Documentation](https://openrouter.ai/docs)
- [Flutter Image Processing](https://pub.dev/packages/image)
- [FFmpeg Kit Flutter](https://pub.dev/packages/ffmpeg_kit_flutter)
