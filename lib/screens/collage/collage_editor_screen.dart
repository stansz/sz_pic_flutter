import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import '../../core/models/image_item.dart';
import '../../core/models/collage_models.dart';

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

  Future<void> _exportCollage() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Capture the collage as an image
      final RenderRepaintBoundary boundary =
          _collageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // Save to device
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/collage_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collage saved to: $filePath'),
            duration: const Duration(seconds: 3),
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
                _exportCollage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Export as JPEG'),
              subtitle: const Text('Smaller file size'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JPEG export coming soon')),
                );
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
            onPressed: () {
              // TODO: Implement background color picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Background color picker coming soon')),
              );
            },
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
                  child: RepaintBoundary(
                    key: _collageKey,
                    child: Container(
                      color: Color(_currentLayout.backgroundColor),
                      child: Stack(
                        children: _currentLayout.cells.map((cell) {
                          final image = _getImageForCell(cell);
                          return _CollageCell(
                            cell: cell,
                            image: image,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          Container(
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
            child: Row(
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
          ),
        ],
      ),
    );
  }
}

class _CollageCell extends StatelessWidget {
  final LayoutCell cell;
  final ImageItem? image;

  const _CollageCell({
    required this.cell,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: cell.x * 1000, // Assuming canvas width of 1000
      top: cell.y * 1000, // Assuming canvas height of 1000
      width: cell.width * 1000,
      height: cell.height * 1000,
      child: Transform.rotate(
        angle: cell.rotation * 3.14159 / 180, // Convert to radians
        child: Transform.scale(
          scale: cell.scale,
          child: image != null
              ? Image.file(
                  File(image!.path),
                  fit: BoxFit.cover,
                )
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
