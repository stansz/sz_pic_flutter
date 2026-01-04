# Getting Started with SZ Pic

This guide will help you get the SZ Pic application running on your Mac M4 with Android Studio.

## Prerequisites

Before you begin, ensure you have:
- Mac M4 (Apple Silicon)
- Android Studio installed
- Xcode Command Line Tools installed

## Step 1: Install Flutter (if not already installed)

```bash
# Using Homebrew (recommended for Mac M4)
brew install flutter

# Verify installation
flutter doctor
```

## Step 2: Install Ollama (for Local AI)

```bash
# Install Ollama
brew install ollama

# Start Ollama service
ollama serve

# In a new terminal, pull the vision model
ollama pull llama3.2-vision
```

Ollama will run on `http://localhost:11434` by default.

## Step 3: Setup the Project

```bash
# Navigate to project directory
cd /Users/sz/StudioProjects/sz_pic_flutter

# Get Flutter dependencies
flutter pub get

# Check for any issues
flutter doctor
```

## Step 4: Configure Android Emulator

1. Open Android Studio
2. Go to **Tools > Device Manager**
3. Create a new **ARM64 virtual device** (not x86_64 for better M4 performance)
4. Recommended: Pixel 7 API 34 (ARM64)

## Step 5: Run the App

### Option A: Using Android Studio
1. Open the project in Android Studio
2. Select your ARM64 emulator or physical device
3. Click the **Run** button (green play icon)

### Option B: Using Command Line
```bash
# List available devices
flutter devices

# Run on Android emulator
flutter run

# Run with specific device
flutter run -d <device-id>
```

## Step 6: Test the Features

### Create Your First Collage
1. Tap **"Create Collage"** on the home screen
2. Select 2-5 images from your gallery
3. Choose a layout style (Grid, Masonry, Template, or Freestyle)
4. Edit and customize your collage
5. Export as PNG or JPEG

### Try the Freestyle Editor
1. Select **"Freestyle Layout"** from the layout options
2. The freestyle editor will open with interactive controls
3. **Tap** any image to select it (shows blue border)
4. **Drag** images to reposition them on the canvas
5. **Resize** using the blue corner handle (bottom-right)
6. **Rotate** using the green rotation handle (top center)
7. Use the **Layers** button to bring images to front or send to back
8. Use **Shuffle** to randomly reassign images
9. Use **Reset** to restore the original layout
10. Export your customized collage

### Test AI Features
1. In the collage creator, tap the **AI suggestions** button (✨ icon)
2. The app will connect to your local Ollama instance
3. Review AI-generated layout suggestions
4. Note: First AI request may take 10-20 seconds as the model loads

## Common Issues & Solutions

### Issue: "flutter: command not found"
**Solution**: Add Flutter to your PATH:
```bash
echo 'export PATH="$PATH:/opt/homebrew/bin"' >> ~/.zshrc
source ~/.zshrc
```

### Issue: "Ollama connection failed"
**Solution**: 
1. Ensure Ollama is running: `ollama serve`
2. Check if the model is downloaded: `ollama list`
3. Pull the model if needed: `ollama pull llama3.2-vision`

### Issue: "No devices found"
**Solution**: 
1. Start your Android emulator first
2. Run `flutter devices` to verify it's detected
3. For physical device, enable USB debugging

### Issue: Image picker not working
**Solution**: The app requires gallery permissions. On first use:
1. The app will request permissions
2. Grant access to photos
3. If denied, go to Settings > Apps > SZ Pic > Permissions

### Issue: Build fails with "Gradle error"
**Solution**:
```bash
# Clean the build
cd android
./gradlew clean
cd ..

# Try again
flutter run
```

### Issue: Slow performance on emulator
**Solution**: 
1. Use an ARM64 emulator (not x86_64)
2. Increase emulator RAM in AVD settings
3. Enable hardware acceleration
4. Consider testing on a physical device

## Project Structure

```
lib/
├── core/
│   ├── models/          # Data models
│   │   ├── image_item.dart
│   │   ├── collage_models.dart
│   │   ├── slideshow_models.dart
│   │   └── ai_models.dart
│   └── services/        # Business logic
│       ├── ai_provider.dart
│       ├── ollama_provider.dart
│       ├── openrouter_provider.dart
│       ├── collage_engine.dart
│       └── image_picker_service.dart
├── screens/            # UI screens
│   ├── home_screen.dart
│   └── collage/
│       ├── collage_creator_screen.dart
│       ├── collage_editor_screen.dart
│       └── freestyle_editor_screen.dart
└── main.dart           # App entry point
```

## Using OpenRouter (Cloud AI) Instead of Ollama

If you prefer cloud AI over local Ollama:

1. Get an API key from [OpenRouter.ai](https://openrouter.ai)
2. Modify [`lib/main.dart`](lib/main.dart):

```dart
// Replace OllamaProvider with OpenRouterProvider
Provider<AIProvider>(
  create: (_) => OpenRouterProvider(
    config: AIProviderConfig.defaultOpenRouter(
      apiKey: 'YOUR_API_KEY_HERE',
    ),
  ),
),
```

## Development Tips

### Hot Reload
While the app is running, make code changes and press:
- `r` - Hot reload (fast, preserves state)
- `R` - Hot restart (slower, fresh state)
- `q` - Quit

### View Logs
```bash
flutter logs
```

### Run in Debug Mode
```bash
flutter run --debug
```

### Run in Release Mode (Better Performance)
```bash
flutter run --release
```

### Format Code
```bash
flutter format lib/
```

### Analyze Code
```bash
flutter analyze
```

## Next Steps

Once you have the app running:

1. **Explore Features**: Try different layout algorithms
2. **Test AI Integration**: Generate AI layout suggestions
3. **Customize**: Modify colors in [`lib/main.dart`](lib/main.dart)
4. **Contribute**: Check [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for pending features

## Need Help?

- Check [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for feature status
- Review [`ARCHITECTURE.md`](planning/ARCHITECTURE.md) for technical details
- See [`MAC_M4_SETUP_GUIDE.md`](planning/MAC_M4_SETUP_GUIDE.md) for Mac-specific optimizations

## Performance Benchmarks (Mac M4)

| Operation | Expected Time |
|-----------|---------------|
| App startup | 2-3 seconds |
| Image selection | < 1 second |
| Layout generation | < 500ms |
| First AI request | 10-20 seconds |
| Subsequent AI requests | 2-5 seconds |
| Collage export (PNG/JPEG) | 1-3 seconds |
| Freestyle editor interactions | < 100ms |

---

**Last Updated**: January 2, 2026  
**Flutter Version**: 3.10.4+  
**Dart Version**: 3.10.4+
