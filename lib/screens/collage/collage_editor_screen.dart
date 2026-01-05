import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../../core/models/image_item.dart';
import '../../core/models/collage_models.dart';
import '../../core/utils/export_helper.dart';
import '../../core/widgets/color_picker_dialog.dart';

enum CollageExportFormat { png, jpeg }

extension on CollageExportFormat {
  String get extension => this == CollageExportFormat.png ? 'png' : 'jpg';
  String get mimeType => this == CollageExportFormat.png ? 'image/png' : 'image/jpeg';
  String get displayName => this == CollageExportFormat.png ? 'PNG' : 'JPEG';
}

class CollageEditorScreen extends StatefulWidget {
  final CollageLayout layout;
  final List<ImageItem> images;

  const CollageEditorScreen({
    super.key,
    required this.layout,
    required this.images,
  });

  @override
  State<CollageEditorScreen> createState() => _CollageEditorScreenState();
}

class _CollageEditorScreenState extends State<CollageEditorScreen> {
  late CollageLayout _currentLayout;
  final GlobalKey _collageKey = GlobalKey();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _currentLayout = widget.layout;
  }

  ImageItem? _getImageForCell(LayoutCell cell) {
    if (cell.imageId == null) return null;
    try {
      return widget.images.firstWhere((img) => img.id == cell.imageId);
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> _captureCollageBytes(CollageExportFormat format) async {
    final RenderRepaintBoundary boundary =
        _collageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    if (format == CollageExportFormat.png) {
      return pngBytes;
    }

    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) {
      throw StateError('Unable to decode collage PNG for JPEG export.');
    }

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
  }

  Future<void> _exportCollage(CollageExportFormat format) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final bytes = await _captureCollageBytes(format);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final displayName = format.displayName;

      if (kIsWeb) {
        final filename = 'collage_$timestamp.${format.extension}';
        downloadImage(bytes, filename, format.mimeType);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$displayName collage download ready: $filename'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Prompt user for a save directory (Android/iOS/desktop)
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save collage',
        lockParentWindow: true,
      );

      if (selectedDirectory == null) {
        if (mounted) {
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
        'collage_$timestamp.${format.extension}',
      );
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$displayName collage saved to: $filePath'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export collage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showColorPicker() async {
    final newColor = await ColorPickerDialog.show(
      context,
      _currentLayout.backgroundColor,
    );

    if (newColor != null && mounted) {
      setState(() {
        _currentLayout = _currentLayout.copyWith(backgroundColor: newColor);
      });
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
                _exportCollage(CollageExportFormat.png);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Export as JPEG'),
              subtitle: const Text('Smaller file size'),
              onTap: () {
                Navigator.pop(context);
                _exportCollage(CollageExportFormat.jpeg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              subtitle: const Text('Print-ready document'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export coming soon')),
                );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Collage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: 'Change Background',
            onPressed: _showColorPicker,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'Export',
            onPressed: _isExporting ? null : _showExportOptions,
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
      body: Column(
        children: [
          // Collage Canvas
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _currentLayout.aspectRatio,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                      return RepaintBoundary(
                        key: _collageKey,
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          color: Color(_currentLayout.backgroundColor),
                          child: Stack(
                            children: _currentLayout.cells.map((cell) {
                              final image = _getImageForCell(cell);
                              return _CollageCell(
                                cell: cell,
                                image: image,
                                canvasSize: canvasSize,
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlButton(
                        icon: Icons.aspect_ratio,
                        label: 'Aspect',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Aspect ratio adjustment coming soon')),
                          );
                        },
                      ),
                      _ControlButton(
                        icon: Icons.space_bar,
                        label: 'Spacing',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Spacing adjustment coming soon')),
                          );
                        },
                      ),
                      _ControlButton(
                        icon: Icons.shuffle,
                        label: 'Shuffle',
                        onPressed: () {
                          setState(() {
                            // Shuffle images in cells
                            final imageIds = _currentLayout.cells
                                .map((c) => c.imageId)
                                .toList()
                              ..shuffle();
                            final updatedCells = <LayoutCell>[];
                            for (var i = 0; i < _currentLayout.cells.length; i++) {
                              updatedCells.add(
                                _currentLayout.cells[i].copyWith(imageId: imageIds[i]),
                              );
                            }
                            _currentLayout = _currentLayout.copyWith(cells: updatedCells);
                          });
                        },
                      ),
                      _ControlButton(
                        icon: Icons.auto_awesome,
                        label: 'AI Enhance',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI enhancement coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollageCell extends StatelessWidget {
  final LayoutCell cell;
  final ImageItem? image;
  final Size canvasSize;

  const _CollageCell({
    required this.cell,
    this.image,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: cell.x * canvasSize.width,
      top: cell.y * canvasSize.height,
      width: cell.width * canvasSize.width,
      height: cell.height * canvasSize.height,
      child: Transform.rotate(
        angle: cell.rotation * math.pi / 180, // Convert to radians
        alignment: Alignment.center,
        child: Transform.scale(
          scale: cell.scale,
          child: image != null
              ? (kIsWeb && image!.bytes != null
                  ? Image.memory(
                      image!.bytes!,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(image!.path),
                      fit: BoxFit.cover,
                    ))
              : Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
