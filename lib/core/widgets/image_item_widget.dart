import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/models/image_item.dart';

/// Helper widget that displays an ImageItem correctly on both web and mobile.
///
/// On web, uses Image.memory() with cached bytes since file paths aren't accessible.
/// On mobile, uses Image.file() for optimal performance.
class ImageItemWidget extends StatelessWidget {
  final ImageItem image;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ImageItemWidget({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && image.bytes != null) {
      // Web: Use cached bytes with Image.memory
      return Image.memory(
        image.bytes!,
        fit: fit,
        width: width,
        height: height,
      );
    } else {
      // Mobile: Use file path with Image.file
      return Image.file(
        File(image.path),
        fit: fit,
        width: width,
        height: height,
      );
    }
  }
}
