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
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../../core/models/image_item.dart';
import '../../core/models/photo_filter.dart';
import '../../core/utils/export_helper.dart';
import '../../core/widgets/filtered_image_preview.dart';
import '../../core/widgets/filter_thumbnail.dart';
import '../../core/widgets/loading_dialog.dart';

enum PhotoExportFormat { png, jpeg }

extension on PhotoExportFormat {
  String get extension => this == PhotoExportFormat.png ? 'png' : 'jpg';
  String get mimeType => this == PhotoExportFormat.png ? 'image/png' : 'image/jpeg';
  String get displayName => this == PhotoExportFormat.png ? 'PNG' : 'JPEG';
}

class PhotoEditorScreen extends StatefulWidget {
  final ImageItem image;

  const PhotoEditorScreen({
    super.key,
    required this.image,
  });

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  PhotoFilterType _selectedFilter = PhotoFilterType.none;
  bool _isProcessing = false;
  final GlobalKey _imageKey = GlobalKey();

  Future<void> _exportImage(PhotoExportFormat format) async {
    setState(() {
      _isProcessing = true;
    });

    LoadingDialog.show(
      context,
      message: 'Exporting filtered photo...',
      showProgress: false,
    );

    try {
      // Capture the filtered widget as image
      final boundary = _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Failed to find image boundary');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert image to bytes');

      Uint8List bytes = byteData.buffer.asUint8List();

      // Convert to JPEG if requested
      if (format == PhotoExportFormat.jpeg) {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) throw Exception('Failed to decode PNG');
        bytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
      }

      // Save image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final displayName = format.displayName;

      if (kIsWeb) {
        final filename = 'photo_${_selectedFilter.name}_$timestamp.${format.extension}';
        downloadImage(bytes, filename, format.mimeType);
        if (mounted) {
          LoadingDialog.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$displayName photo download ready: $filename'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Native platforms: prompt for save location
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save photo',
        lockParentWindow: true,
      );

      if (selectedDirectory == null) {
        if (mounted) {
          LoadingDialog.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$displayName export canceled'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final filePath = p.join(
        selectedDirectory,
        'photo_${_selectedFilter.name}_$timestamp.${format.extension}',
      );
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$displayName photo saved to: $filePath'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Export as PNG'),
              subtitle: const Text('High quality image'),
              onTap: () {
                Navigator.pop(context);
                _exportImage(PhotoExportFormat.png);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Export as JPEG'),
              subtitle: const Text('Smaller file size'),
              onTap: () {
                Navigator.pop(context);
                _exportImage(PhotoExportFormat.jpeg);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = PhotoFilter.fromType(_selectedFilter);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            tooltip: 'Export',
            onPressed: _isProcessing ? null : _showExportOptions,
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Return to Home',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // REAL-TIME PREVIEW - Main image with filter applied
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RepaintBoundary(
                    key: _imageKey,
                    child: FilteredImagePreview(
                      image: kIsWeb && widget.image.bytes != null
                          ? MemoryImage(widget.image.bytes!)
                          : FileImage(File(widget.image.path)) as ImageProvider,
                      filter: filter,
                    ),
                  ),
                ),
              ),
            ),

            // Filter selector (Instagram-style horizontal scroll)
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: PhotoFilterType.values.length,
                itemBuilder: (context, index) {
                  final filterType = PhotoFilterType.values[index];
                  return FilterThumbnail(
                    image: widget.image,
                    filterType: filterType,
                    isSelected: _selectedFilter == filterType,
                    onTap: () {
                      setState(() {
                        _selectedFilter = filterType;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
