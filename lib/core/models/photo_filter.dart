import 'dart:ui';
import 'package:equatable/equatable.dart';

/// Photo filter types with predefined visual characteristics
enum PhotoFilterType {
  none,           // Original image
  vintage,        // Warm sepia with slight fade
  blackAndWhite,  // Classic B&W with enhanced contrast
  cool,           // Blue/cyan tones for modern look
  warm,           // Orange/yellow sunset vibes
  vibrant,        // Enhanced saturation
  muted,          // Desaturated soft tones
  dramatic,       // High contrast deep blacks
}

extension PhotoFilterTypeExtension on PhotoFilterType {
  String get displayName {
    switch (this) {
      case PhotoFilterType.none:
        return 'Original';
      case PhotoFilterType.vintage:
        return 'Vintage';
      case PhotoFilterType.blackAndWhite:
        return 'B&W';
      case PhotoFilterType.cool:
        return 'Cool';
      case PhotoFilterType.warm:
        return 'Warm';
      case PhotoFilterType.vibrant:
        return 'Vibrant';
      case PhotoFilterType.muted:
        return 'Muted';
      case PhotoFilterType.dramatic:
        return 'Dramatic';
    }
  }

  String get description {
    switch (this) {
      case PhotoFilterType.none:
        return 'No filter applied';
      case PhotoFilterType.vintage:
        return 'Warm sepia tones with slight fade';
      case PhotoFilterType.blackAndWhite:
        return 'Classic black & white with boosted contrast';
      case PhotoFilterType.cool:
        return 'Cool blue/cyan tones';
      case PhotoFilterType.warm:
        return 'Warm orange/yellow sunset tones';
      case PhotoFilterType.vibrant:
        return 'Enhanced color saturation';
      case PhotoFilterType.muted:
        return 'Soft desaturated tones';
      case PhotoFilterType.dramatic:
        return 'High contrast with deep blacks';
    }
  }
}

/// Photo filter with GPU-accelerated rendering properties
class PhotoFilter extends Equatable {
  final PhotoFilterType type;
  final ColorFilter? colorFilter;
  final ImageFilter? imageFilter;

  const PhotoFilter({
    required this.type,
    this.colorFilter,
    this.imageFilter,
  });

  /// Factory method to create filter from type
  factory PhotoFilter.fromType(PhotoFilterType type) {
    switch (type) {
      case PhotoFilterType.none:
        return PhotoFilter.none();
      case PhotoFilterType.vintage:
        return PhotoFilter.vintage();
      case PhotoFilterType.blackAndWhite:
        return PhotoFilter.blackAndWhite();
      case PhotoFilterType.cool:
        return PhotoFilter.cool();
      case PhotoFilterType.warm:
        return PhotoFilter.warm();
      case PhotoFilterType.vibrant:
        return PhotoFilter.vibrant();
      case PhotoFilterType.muted:
        return PhotoFilter.muted();
      case PhotoFilterType.dramatic:
        return PhotoFilter.dramatic();
    }
  }

  /// No filter
  factory PhotoFilter.none() {
    return const PhotoFilter(type: PhotoFilterType.none);
  }

  /// Vintage sepia filter
  factory PhotoFilter.vintage() {
    return PhotoFilter(
      type: PhotoFilterType.vintage,
      colorFilter: const ColorFilter.matrix([
        0.393, 0.769, 0.189, 0, 0,  // Red channel
        0.349, 0.686, 0.168, 0, 0,  // Green channel
        0.272, 0.534, 0.131, 0, 0,  // Blue channel
        0,     0,     0,     1, 0,  // Alpha channel
      ]),
    );
  }

  /// Black & white with contrast boost
  factory PhotoFilter.blackAndWhite() {
    return PhotoFilter(
      type: PhotoFilterType.blackAndWhite,
      colorFilter: const ColorFilter.matrix([
        0.33, 0.33, 0.33, 0, 0,   // Red = average
        0.33, 0.33, 0.33, 0, 0,   // Green = average
        0.33, 0.33, 0.33, 0, 0,   // Blue = average
        0,    0,    0,    1, 0,   // Alpha unchanged
      ]),
    );
  }

  /// Cool blue/cyan tones
  factory PhotoFilter.cool() {
    return PhotoFilter(
      type: PhotoFilterType.cool,
      colorFilter: const ColorFilter.matrix([
        0.9, 0,   0,   0, 0,   // Slightly reduce red
        0,   1.0, 0,   0, 10,  // Keep green, slight boost
        0,   0,   1.1, 0, 20,  // Boost blue
        0,   0,   0,   1, 0,   // Alpha unchanged
      ]),
    );
  }

  /// Warm orange/yellow tones
  factory PhotoFilter.warm() {
    return PhotoFilter(
      type: PhotoFilterType.warm,
      colorFilter: const ColorFilter.matrix([
        1.1, 0,   0,   0, 20,  // Boost red
        0,   1.0, 0,   0, 10,  // Slight green boost
        0,   0,   0.9, 0, 0,   // Reduce blue
        0,   0,   0,   1, 0,   // Alpha unchanged
      ]),
    );
  }

  /// Enhanced saturation
  factory PhotoFilter.vibrant() {
    const saturation = 1.5; // 50% more saturated
    const sr = (1 - saturation) * 0.3086;
    const sg = (1 - saturation) * 0.6094;
    const sb = (1 - saturation) * 0.0820;

    return PhotoFilter(
      type: PhotoFilterType.vibrant,
      colorFilter: ColorFilter.matrix([
        sr + saturation, sg,              sb,              0, 0,
        sr,              sg + saturation, sb,              0, 0,
        sr,              sg,              sb + saturation, 0, 0,
        0,               0,               0,               1, 0,
      ]),
    );
  }

  /// Desaturated soft tones
  factory PhotoFilter.muted() {
    const saturation = 0.5; // 50% less saturated
    const sr = (1 - saturation) * 0.3086;
    const sg = (1 - saturation) * 0.6094;
    const sb = (1 - saturation) * 0.0820;

    return PhotoFilter(
      type: PhotoFilterType.muted,
      colorFilter: ColorFilter.matrix([
        sr + saturation, sg,              sb,              0, 0,
        sr,              sg + saturation, sb,              0, 0,
        sr,              sg,              sb + saturation, 0, 0,
        0,               0,               0,               1, 0,
      ]),
    );
  }

  /// High contrast dramatic look
  factory PhotoFilter.dramatic() {
    const contrast = 1.3;
    const offset = -(0.5 * contrast - 0.5) * 255;

    return PhotoFilter(
      type: PhotoFilterType.dramatic,
      colorFilter: ColorFilter.matrix([
        contrast, 0,        0,        0, offset,
        0,        contrast, 0,        0, offset,
        0,        0,        contrast, 0, offset,
        0,        0,        0,        1, 0,
      ]),
    );
  }

  @override
  List<Object?> get props => [type, colorFilter, imageFilter];
}
