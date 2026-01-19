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

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import '../models/image_item.dart';

/// Service for picking and managing images
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Pick a single image from gallery
  Future<ImageItem?> pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return null;

      return await _createImageItem(file);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<ImageItem>> pickMultipleImages({int? limit}) async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (files.isEmpty) return [];

      final images = <ImageItem>[];
      final filesToProcess = limit != null && files.length > limit
          ? files.sublist(0, limit)
          : files;

      for (final file in filesToProcess) {
        final imageItem = await _createImageItem(file);
        if (imageItem != null) {
          images.add(imageItem);
        }
      }

      return images;
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  /// Take a photo using camera
  Future<ImageItem?> takePhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (file == null) return null;

      return await _createImageItem(file);
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Create ImageItem from XFile with metadata
  Future<ImageItem?> _createImageItem(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      final size = await file.length();
      final resolvedPath = file.path.isNotEmpty
          ? file.path
          : (kIsWeb ? 'web:${file.name}' : 'unknown:${file.name}');
      final cachedBytes = kIsWeb ? bytes : null;

      return ImageItem(
        id: _uuid.v4(),
        path: resolvedPath,
        name: file.name,
        addedAt: DateTime.now(),
        width: image.width,
        height: image.height,
        fileSize: size,
        bytes: cachedBytes,
      );
    } catch (e) {
      return null;
    }
  }
}
