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

enum CollageExportFormat { png, jpeg }

extension on CollageExportFormat {
  String get extension => this == CollageExportFormat.png ? 'png' : 'jpg';
  String get mimeType =>
      this == CollageExportFormat.png ? 'image/png' : 'image/jpeg';
  String get displayName => this == CollageExportFormat.png ? 'PNG' : 'JPEG';
}

class FreestyleEditorScreen extends StatefulWidget {
  final CollageLayout layout;
  final List<ImageItem> images;

  const FreestyleEditorScreen({
    super.key,
    required this.layout,
    required this.images,
  });

  @override
  State<FreestyleEditorScreen> createState() => _FreestyleEditorScreenState();
}

class _FreestyleEditorScreenState extends State<FreestyleEditorScreen> {
  late CollageLayout _currentLayout;
  final GlobalKey _collageKey = GlobalKey();
  bool _isExporting = false;
  String? _selectedCellId;
  Offset? _dragStartOffset;
  Offset? _cellStartOffset;
  double? _resizeStartDistance;
  Size? _cellStartSize;

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
            action: SnackBarAction(label: 'OK', onPressed: () {}),
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
          ],
        ),
      ),
    );
  }

  void _updateCellPosition(String cellId, Offset newPosition, Size canvasSize) {
    final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1) return;

    final cell = _currentLayout.cells[cellIndex];
    final newX = (newPosition.dx / canvasSize.width).clamp(
      0.0,
      1.0 - cell.width,
    );
    final newY = (newPosition.dy / canvasSize.height).clamp(
      0.0,
      1.0 - cell.height,
    );

    final updatedCell = cell.copyWith(x: newX, y: newY);
    final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
    updatedCells[cellIndex] = updatedCell;

    setState(() {
      _currentLayout = _currentLayout.copyWith(cells: updatedCells);
    });
  }

  void _updateCellSize(String cellId, Size newSize, Size canvasSize) {
    final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1) return;

    final cell = _currentLayout.cells[cellIndex];
    final newWidth = (newSize.width / canvasSize.width).clamp(
      0.1,
      1.0 - cell.x,
    );
    final newHeight = (newSize.height / canvasSize.height).clamp(
      0.1,
      1.0 - cell.y,
    );

    final updatedCell = cell.copyWith(width: newWidth, height: newHeight);
    final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
    updatedCells[cellIndex] = updatedCell;

    setState(() {
      _currentLayout = _currentLayout.copyWith(cells: updatedCells);
    });
  }

  void _updateCellRotation(String cellId, double newRotation) {
    final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1) return;

    final cell = _currentLayout.cells[cellIndex];
    final updatedCell = cell.copyWith(rotation: newRotation);
    final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
    updatedCells[cellIndex] = updatedCell;

    setState(() {
      _currentLayout = _currentLayout.copyWith(cells: updatedCells);
    });
  }

  void _bringToFront(String cellId) {
    final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1 || cellIndex == _currentLayout.cells.length - 1) return;

    final cell = _currentLayout.cells[cellIndex];
    final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
    updatedCells.removeAt(cellIndex);
    updatedCells.add(cell);

    setState(() {
      _currentLayout = _currentLayout.copyWith(cells: updatedCells);
    });
  }

  void _sendToBack(String cellId) {
    final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1 || cellIndex == 0) return;

    final cell = _currentLayout.cells[cellIndex];
    final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
    updatedCells.removeAt(cellIndex);
    updatedCells.insert(0, cell);

    setState(() {
      _currentLayout = _currentLayout.copyWith(cells: updatedCells);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Freestyle Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: 'Change Background',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Background color picker coming soon'),
                ),
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
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap to select • Drag to move • Drag corners to resize • Use rotation control below',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                      final canvasSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );

                      return RepaintBoundary(
                        key: _collageKey,
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          color: Color(_currentLayout.backgroundColor),
                          child: Stack(
                            children: _currentLayout.cells.map((cell) {
                              final image = _getImageForCell(cell);
                              final isSelected = _selectedCellId == cell.id;
                              return _FreestyleCell(
                                cell: cell,
                                image: image,
                                canvasSize: canvasSize,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedCellId = cell.id;
                                  });
                                },
                                onDragStart: (details) {
                                  setState(() {
                                    _selectedCellId = cell.id;
                                    _dragStartOffset = details.globalPosition;
                                    _cellStartOffset = Offset(
                                      cell.x * canvasSize.width,
                                      cell.y * canvasSize.height,
                                    );
                                  });
                                },
                                onDragUpdate: (details) {
                                  if (_dragStartOffset != null &&
                                      _cellStartOffset != null) {
                                    final delta =
                                        details.globalPosition -
                                        _dragStartOffset!;
                                    final newPosition =
                                        _cellStartOffset! + delta;
                                    _updateCellPosition(
                                      cell.id,
                                      newPosition,
                                      canvasSize,
                                    );
                                  }
                                },
                                onDragEnd: (details) {
                                  setState(() {
                                    _dragStartOffset = null;
                                    _cellStartOffset = null;
                                  });
                                },
                                onResizeStart: (details) {
                                  setState(() {
                                    _selectedCellId = cell.id;
                                    _resizeStartDistance =
                                        details.globalPosition.distance;
                                    _cellStartSize = Size(
                                      cell.width * canvasSize.width,
                                      cell.height * canvasSize.height,
                                    );
                                  });
                                },
                                onResizeUpdate: (details) {
                                  if (_resizeStartDistance != null &&
                                      _cellStartSize != null) {
                                    final currentDistance =
                                        details.globalPosition.distance;
                                    final scale =
                                        currentDistance / _resizeStartDistance!;
                                    final newSize = Size(
                                      _cellStartSize!.width * scale,
                                      _cellStartSize!.height * scale,
                                    );
                                    _updateCellSize(
                                      cell.id,
                                      newSize,
                                      canvasSize,
                                    );
                                  }
                                },
                                onResizeEnd: (details) {
                                  setState(() {
                                    _resizeStartDistance = null;
                                    _cellStartSize = null;
                                  });
                                },
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
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 12,
                runSpacing: 8,
                children: [
                  _ControlButton(
                    icon: Icons.rotate_right,
                    label: 'Rotate',
                    onPressed: _showRotationOptions,
                  ),
                  _ControlButton(
                    icon: Icons.shuffle,
                    label: 'Shuffle',
                    onPressed: () {
                      setState(() {
                        final imageIds =
                            _currentLayout.cells.map((c) => c.imageId).toList()
                              ..shuffle();
                        final updatedCells = <LayoutCell>[];
                        for (var i = 0; i < _currentLayout.cells.length; i++) {
                          updatedCells.add(
                            _currentLayout.cells[i].copyWith(
                              imageId: imageIds[i],
                            ),
                          );
                        }
                        _currentLayout = _currentLayout.copyWith(
                          cells: updatedCells,
                        );
                      });
                    },
                  ),
                  _ControlButton(
                    icon: Icons.refresh,
                    label: 'Reset',
                    onPressed: () {
                      setState(() {
                        _currentLayout = widget.layout;
                        _selectedCellId = null;
                      });
                    },
                  ),
                  _ControlButton(
                    icon: Icons.layers,
                    label: 'Layer',
                    onPressed: () {
                      if (_selectedCellId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select a cell to adjust layers'),
                          ),
                        );
                        return;
                      }
                      _showLayerOptions(_selectedCellId!);
                    },
                  ),
                  _ControlButton(
                    icon: Icons.auto_awesome,
                    label: 'AI Enhance',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI enhancement coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLayerOptions(String cellId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flip_to_front),
              title: const Text('Bring to Front'),
              onTap: () {
                Navigator.pop(context);
                _bringToFront(cellId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flip_to_back),
              title: const Text('Send to Back'),
              onTap: () {
                Navigator.pop(context);
                _sendToBack(cellId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRotationOptions() {
    if (_selectedCellId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a cell to rotate')));
      return;
    }

    final cell = _currentLayout.cells.firstWhere(
      (c) => c.id == _selectedCellId,
      orElse: () => _currentLayout.cells.first,
    );
    final theme = Theme.of(context);
    double sliderValue = (cell.rotation % 360 + 360) % 360;

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Rotation', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Slider(
                  min: 0,
                  max: 360,
                  divisions: 360,
                  value: sliderValue,
                  label: '${sliderValue.toStringAsFixed(0)}°',
                  onChanged: (value) {
                    setModalState(() => sliderValue = value);
                    _updateCellRotation(_selectedCellId!, value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sliderValue.toStringAsFixed(0)}°',
                      style: theme.textTheme.bodyLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() => sliderValue = 0);
                        _updateCellRotation(_selectedCellId!, 0);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FreestyleCell extends StatelessWidget {
  final LayoutCell cell;
  final ImageItem? image;
  final Size canvasSize;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(DragStartDetails) onDragStart;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails) onDragEnd;
  final Function(DragStartDetails) onResizeStart;
  final Function(DragUpdateDetails) onResizeUpdate;
  final Function(DragEndDetails) onResizeEnd;

  const _FreestyleCell({
    required this.cell,
    this.image,
    required this.canvasSize,
    required this.isSelected,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final cellWidth = cell.width * canvasSize.width;
    final cellHeight = cell.height * canvasSize.height;
    final cellX = cell.x * canvasSize.width;
    final cellY = cell.y * canvasSize.height;

    return Positioned(
      left: cellX,
      top: cellY,
      width: cellWidth,
      height: cellHeight,
      child: GestureDetector(
        onTap: onTap,
        onPanStart: onDragStart,
        onPanUpdate: onDragUpdate,
        onPanEnd: onDragEnd,
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              // Image
              Transform.rotate(
                angle: cell.rotation * math.pi / 180,
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: cell.scale,
                  child: image != null
                      ? (kIsWeb && image!.bytes != null
                            ? Image.memory(
                                image!.bytes!,
                                fit: BoxFit.cover,
                                width: cellWidth,
                                height: cellHeight,
                              )
                            : Image.file(
                                File(image!.path),
                                fit: BoxFit.cover,
                                width: cellWidth,
                                height: cellHeight,
                              ))
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),

              // Selection controls
              if (isSelected) ...[
                // Resize handle (bottom-right corner)
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: GestureDetector(
                    onPanStart: onResizeStart,
                    onPanUpdate: onResizeUpdate,
                    onPanEnd: onResizeEnd,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.open_in_full,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
