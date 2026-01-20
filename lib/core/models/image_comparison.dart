import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Comparison modes for before/after image comparison
enum ComparisonMode {
  slider,      // Drag slider to reveal
  swipe,       // Swipe gesture to toggle
  sideBySide,  // Split view
}

/// Model representing a before/after image comparison configuration
class ImageComparison extends Equatable {
  /// Path to the before (original) image
  final String beforeImagePath;

  /// Path to the after (filtered/edited) image
  final String afterImagePath;

  /// Current slider position (0.0 to 1.0)
  final double sliderPosition;

  /// Comparison mode
  final ComparisonMode mode;

  /// Whether to show labels on the images
  final bool showLabels;

  /// Label text for the before image
  final String beforeLabel;

  /// Label text for the after image
  final String afterLabel;

  /// Color of the slider handle
  final Color sliderColor;

  /// Width of the slider line
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

  /// Creates a copy of this model with optional field updates
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
