import 'package:flutter/material.dart';
import '../models/photo_filter.dart';

/// Widget that displays an image with a filter applied in real-time
/// Uses GPU-accelerated rendering for 60fps performance
class FilteredImagePreview extends StatelessWidget {
  final ImageProvider image;
  final PhotoFilter filter;
  final BoxFit fit;

  const FilteredImagePreview({
    super.key,
    required this.image,
    required this.filter,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Image(
      image: image,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.error_outline, size: 48, color: Colors.red),
        );
      },
    );

    // Apply color filter if present (GPU-accelerated)
    if (filter.colorFilter != null) {
      child = ColorFiltered(
        colorFilter: filter.colorFilter!,
        child: child,
      );
    }

    // Apply image filter if present (GPU-accelerated)
    if (filter.imageFilter != null) {
      child = ImageFiltered(
        imageFilter: filter.imageFilter!,
        child: child,
      );
    }

    return child;
  }
}
