// Copyright (c) 2026
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
