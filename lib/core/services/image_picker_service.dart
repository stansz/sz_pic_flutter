import 'dart:io';
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

      final fileStats = await File(file.path).stat();

      return ImageItem(
        id: _uuid.v4(),
        path: file.path,
        name: file.name,
        addedAt: DateTime.now(),
        width: image.width,
        height: image.height,
        fileSize: fileStats.size,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get aspect ratio of an image
  Future<double?> getAspectRatio(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      return image.width / image.height;
    } catch (e) {
      return null;
    }
  }

  /// Get image dimensions
  Future<Map<String, int>?> getImageDimensions(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      return null;
    }
  }
}
