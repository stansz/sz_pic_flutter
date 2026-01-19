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
