import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/collage_models.dart';
import '../models/slideshow_models.dart';
import '../models/image_item.dart';
import '../models/photo_filter.dart';
import '../widgets/image_item_widget.dart';
import '../widgets/filtered_image_preview.dart';

/// Service for generating project thumbnails
class ThumbnailGenerator {
  /// Generate thumbnail for collage project
  static Future<String> generateCollageThumbnail(
    CollageLayout layout,
    List<ImageItem> images,
    String projectId,
  ) async {
    if (kIsWeb) {
      throw UnsupportedError('Thumbnail generation not supported on web');
    }

    // Create a widget to capture
    final widget = _CollageThumbnailWidget(
      layout: layout,
      images: images,
    );

    return await _captureWidget(widget, projectId);
  }

  /// Generate thumbnail for slideshow project
  static Future<String> generateSlideshowThumbnail(
    SlideshowProject project,
    String projectId,
  ) async {
    if (kIsWeb) {
      throw UnsupportedError('Thumbnail generation not supported on web');
    }

    // Use first slide as thumbnail
    if (project.slides.isEmpty) {
      throw ArgumentError('Slideshow project has no slides');
    }

    final firstSlide = project.slides.first;
    final widget = _SlideshowThumbnailWidget(
      imagePath: firstSlide.image.path,
    );

    return await _captureWidget(widget, projectId);
  }

  /// Generate thumbnail for photo edit
  static Future<String> generatePhotoThumbnail(
    ImageItem image,
    PhotoFilter filter,
    String projectId,
  ) async {
    if (kIsWeb) {
      throw UnsupportedError('Thumbnail generation not supported on web');
    }

    final widget = _PhotoThumbnailWidget(
      image: image,
      filter: filter,
    );

    return await _captureWidget(widget, projectId);
  }

  /// Capture widget as thumbnail image
  static Future<String> _captureWidget(
    Widget widget,
    String projectId,
  ) async {
    if (kIsWeb) {
      throw UnsupportedError('Thumbnail generation not supported on web');
    }

    // Create a GlobalKey to access the RenderRepaintBoundary
    final GlobalKey repaintBoundaryKey = GlobalKey();

    // Build the widget in a MaterialApp
    final appWidget = MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: repaintBoundaryKey,
        child: Material(
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: widget,
            ),
          ),
        ),
      ),
    );

    // Create a binding if needed
    if (!WidgetsBinding.instance.hasScheduledFrame) {
      WidgetsFlutterBinding.ensureInitialized();
    }

    // Capture the widget
    await Future.delayed(const Duration(milliseconds: 200));

    final RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;

    final ui.Image image = await boundary.toImage(
      pixelRatio: 1.0,
    );

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Failed to capture widget as image');
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    // Save to file
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory('${documentsDirectory.path}/thumbnails');
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    final thumbnailPath = path.join(thumbnailsDir.path, '$projectId.png');
    final thumbnailFile = File(thumbnailPath);
    await thumbnailFile.writeAsBytes(pngBytes);

    return thumbnailPath;
  }
}

/// Widget for rendering collage thumbnail
class _CollageThumbnailWidget extends StatelessWidget {
  final CollageLayout layout;
  final List<ImageItem> images;

  const _CollageThumbnailWidget({
    required this.layout,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(layout.backgroundColor),
      child: Stack(
        children: layout.cells.map((cell) {
          final image = images.firstWhere(
            (img) => img.id == cell.imageId,
            orElse: () => images.first,
          );

          return Positioned(
            left: cell.x * 200,
            top: cell.y * 200,
            width: cell.width * 200,
            height: cell.height * 200,
            child: Transform.rotate(
              angle: cell.rotation * 3.14159 / 180,
              child: ImageItemWidget(
                image: image,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget for rendering slideshow thumbnail
class _SlideshowThumbnailWidget extends StatelessWidget {
  final String imagePath;

  const _SlideshowThumbnailWidget({
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
    );
  }
}

/// Widget for rendering photo thumbnail
class _PhotoThumbnailWidget extends StatelessWidget {
  final ImageItem image;
  final PhotoFilter filter;

  const _PhotoThumbnailWidget({
    required this.image,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return FilteredImagePreview(
      image: FileImage(File(image.path)),
      filter: filter,
    );
  }
}
