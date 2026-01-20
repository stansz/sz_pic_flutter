import 'package:flutter/material.dart';
import '../models/image_comparison.dart';

/// Service for managing image comparison configurations and presets
class ImageComparisonService {
  /// Creates a default comparison configuration
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

  /// Returns preset slider colors for user selection
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

  /// Returns all available comparison modes
  static List<ComparisonMode> getAvailableModes() {
    return ComparisonMode.values;
  }

  /// Gets display name for a comparison mode
  static String getModeDisplayName(ComparisonMode mode) {
    switch (mode) {
      case ComparisonMode.slider:
        return 'Slider';
      case ComparisonMode.swipe:
        return 'Swipe';
      case ComparisonMode.sideBySide:
        return 'Side by Side';
    }
  }
}
