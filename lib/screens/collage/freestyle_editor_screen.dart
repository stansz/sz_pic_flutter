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
  bool _isInFreeCropMode = false;
  Offset? _freeCropStartOffset;
  String? _activeCornerId;
  double? _originalCellWidth;
  double? _originalCellHeight;
  double? _originalCellX;
  double? _originalCellY;

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

  void _updateCellImageOffset(String cellId, double offsetX, double offsetY, Size cellSize) {
    final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1) return;

    final cell = _currentLayout.cells[cellIndex];
    
    // Convert pixel offset to normalized offset (-0.5 to 0.5 range)
    final normalizedOffsetX = (offsetX / cellSize.width).clamp(-0.5, 0.5);
    final normalizedOffsetY = (offsetY / cellSize.height).clamp(-0.5, 0.5);

    final updatedCell = cell.copyWith(
      imageOffsetX: normalizedOffsetX,
      imageOffsetY: normalizedOffsetY,
    );
    final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
    updatedCells[cellIndex] = updatedCell;

    setState(() {
      _currentLayout = _currentLayout.copyWith(cells: updatedCells);
    });
  }

  void _updateCellImageScaleAndOffset(String cellId, double newScale, double offsetX, double offsetY, Size cellSize) {
    final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1) return;

    final cell = _currentLayout.cells[cellIndex];
    
    // Clamp scale to reasonable range
    final clampedScale = newScale.clamp(0.5, 3.0);
    
    // Convert pixel offset to normalized offset (-0.5 to 0.5 range)
    final normalizedOffsetX = (offsetX / cellSize.width).clamp(-0.5, 0.5);
    final normalizedOffsetY = (offsetY / cellSize.height).clamp(-0.5, 0.5);

    final updatedCell = cell.copyWith(
      scale: clampedScale,
      imageOffsetX: normalizedOffsetX,
      imageOffsetY: normalizedOffsetY,
    );
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

  void _exitFreeCropMode() {
    if (_selectedCellId != null && _originalCellWidth != null && _originalCellHeight != null && _originalCellX != null && _originalCellY != null) {
      final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == _selectedCellId);
      if (cellIndex != -1) {
        final cell = _currentLayout.cells[cellIndex];
        final updatedCell = cell.copyWith(
          x: _originalCellX!,
          y: _originalCellY!,
          width: _originalCellWidth!,
          height: _originalCellHeight!,
        );
        final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
        updatedCells[cellIndex] = updatedCell;
        setState(() {
          _currentLayout = _currentLayout.copyWith(cells: updatedCells);
          _isInFreeCropMode = false;
          _freeCropStartOffset = null;
          _activeCornerId = null;
          // Keep original dimensions stored? We'll keep them for future re-entry? Reset to null.
          _originalCellWidth = null;
          _originalCellHeight = null;
          _originalCellX = null;
          _originalCellY = null;
        });
        return;
      }
    }
    setState(() {
      _isInFreeCropMode = false;
      _freeCropStartOffset = null;
      _activeCornerId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isInFreeCropMode ? 'Free Crop' : 'Freestyle Editor'),
        actions: [
          if (_isInFreeCropMode)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Done',
              onPressed: _exitFreeCropMode,
            ),
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
            color: _isInFreeCropMode 
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  _isInFreeCropMode ? Icons.crop_free : Icons.info_outline,
                  size: 20,
                  color: _isInFreeCropMode 
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isInFreeCropMode 
                        ? 'Drag corners to resize • Drag center to pan'
                        : 'Tap to select • Drag to move • Drag corners to resize • Use rotation control below',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isInFreeCropMode 
                          ? theme.colorScheme.onTertiaryContainer
                          : theme.colorScheme.onPrimaryContainer,
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
                        color: Colors.black.withValues(alpha: 0.2),
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
                            children: [
                              ..._currentLayout.cells.map((cell) {
                                final image = _getImageForCell(cell);
                                final isSelected = _selectedCellId == cell.id;
                                return _FreestyleCell(
                                  cell: cell,
                                  image: image,
                                  canvasSize: canvasSize,
                                  isSelected: isSelected,
                                  isInFreeCropMode: _isInFreeCropMode && isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedCellId = cell.id;
                                    });
                                  },
                                  onDragStart: (details) {
                                    if (_isInFreeCropMode && _selectedCellId == cell.id) {
                                      // Free crop mode: start tracking image offset
                                      setState(() {
                                        _dragStartOffset = details.globalPosition;
                                        _freeCropStartOffset = Offset(
                                          cell.imageOffsetX * canvasSize.width,
                                          cell.imageOffsetY * canvasSize.height,
                                        );
                                      });
                                    } else {
                                      // Normal mode: move cell
                                      setState(() {
                                        _selectedCellId = cell.id;
                                        _dragStartOffset = details.globalPosition;
                                        _cellStartOffset = Offset(
                                          cell.x * canvasSize.width,
                                          cell.y * canvasSize.height,
                                        );
                                      });
                                    }
                                  },
                                  onDragUpdate: (details) {
                                    if (_isInFreeCropMode && _selectedCellId == cell.id && _freeCropStartOffset != null) {
                                      // Free crop mode: update image offset
                                      final delta = details.globalPosition - _dragStartOffset!;
                                      final newOffset = _freeCropStartOffset! + delta;
                                      _updateCellImageOffset(cell.id, newOffset.dx, newOffset.dy, canvasSize);
                                    } else if (_dragStartOffset != null && _cellStartOffset != null) {
                                      // Normal mode: move cell
                                      final delta = details.globalPosition - _dragStartOffset!;
                                      final newPosition = _cellStartOffset! + delta;
                                      _updateCellPosition(
                                        cell.id,
                                        newPosition,
                                        canvasSize,
                                      );
                                    }
                                  },
                                  onDragEnd: (details) {
                                    setState(() {
                                      if (_isInFreeCropMode) {
                                        _freeCropStartOffset = null;
                                        _activeCornerId = null;
                                      } else {
                                        _dragStartOffset = null;
                                        _cellStartOffset = null;
                                      }
                                    });
                                  },
                                  onResizeStart: (details, cornerId) {
                                    setState(() {
                                      _selectedCellId = cell.id;
                                      _activeCornerId = cornerId;
                                      _dragStartOffset = details.globalPosition;
                                      _resizeStartDistance = details.globalPosition.distance;
                                      _cellStartSize = Size(
                                        cell.width * canvasSize.width,
                                        cell.height * canvasSize.height,
                                      );
                                      _freeCropStartOffset = Offset(
                                        cell.imageOffsetX * canvasSize.width,
                                        cell.imageOffsetY * canvasSize.height,
                                      );
                                    });
                                  },
                                  onResizeUpdate: (details, cornerId) {
                                    if (_dragStartOffset != null && _cellStartSize != null && _freeCropStartOffset != null) {
                                      if (_isInFreeCropMode && _selectedCellId == cell.id) {
                                        // Free crop mode: resize image with corner
                                        final currentDistance = details.globalPosition.distance;
                                        final scaleDelta = currentDistance / (_resizeStartDistance ?? 1.0);
                                        
                                        // Calculate new scale based on corner drag
                                        final cellCenterX = cell.width * canvasSize.width / 2;
                                        final cellCenterY = cell.height * canvasSize.height / 2;
                                        final dragVector = details.globalPosition - _dragStartOffset!;
                                        
                                        // Adjust scale based on drag distance
                                        final newScale = cell.scale * (1.0 + dragVector.distance / 500);
                                        
                                        // Update offset based on which corner
                                        double newOffsetX = _freeCropStartOffset!.dx;
                                        double newOffsetY = _freeCropStartOffset!.dy;
                                        
                                        // Adjust offset based on corner
                                        if (cornerId == 'tl' || cornerId == 'bl') {
                                          newOffsetX += dragVector.dx / 2;
                                        }
                                        if (cornerId == 'tl' || cornerId == 'tr') {
                                          newOffsetY += dragVector.dy / 2;
                                        }
                                        
                                        _updateCellImageScaleAndOffset(
                                          cell.id,
                                          newScale,
                                          newOffsetX,
                                          newOffsetY,
                                          canvasSize,
                                        );
                                      } else {
                                        // Normal mode: resize cell
                                        final currentDistance = details.globalPosition.distance;
                                        final scale = currentDistance / (_resizeStartDistance ?? 1.0);
                                        final newSize = Size(
                                          _cellStartSize!.width * scale,
                                          _cellStartSize!.height * scale,
                                        );
                                        _updateCellSize(cell.id, newSize, canvasSize);
                                      }
                                    }
                                  },
                                  onResizeEnd: (details) {
                                    setState(() {
                                      _resizeStartDistance = null;
                                      _cellStartSize = null;
                                      _freeCropStartOffset = null;
                                      _activeCornerId = null;
                                    });
                                  },
                                );
                              }),
                            ],
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                    icon: Icons.refresh,
                    label: 'Reset',
                    onPressed: () {
                      setState(() {
                        _currentLayout = widget.layout;
                        _selectedCellId = null;
                        _isInFreeCropMode = false;
                        _freeCropStartOffset = null;
                        _activeCornerId = null;
                      });
                    },
                  ),
                  _ControlButton(
                    icon: Icons.crop,
                    label: _isInFreeCropMode ? 'Done' : 'Crop',
                    onPressed: _isInFreeCropMode 
                        ? _exitFreeCropMode 
                        : _showCropOptions,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rotation', style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.check),
                      color: theme.colorScheme.primary,
                      tooltip: 'Apply rotation',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
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

  void _showCropOptions() {
    if (_selectedCellId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a cell to crop')),
      );
      return;
    }

    final cell = _currentLayout.cells.firstWhere(
      (c) => c.id == _selectedCellId,
      orElse: () => _currentLayout.cells.first,
    );
    final image = _getImageForCell(cell);

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image in selected cell')),
      );
      return;
    }

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Crop Image',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const Divider(),
            _buildCropOption(context, 'Free (full screen)', 0),
            _buildCropOption(context, '1:1 (Square)', 1),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCropOption(BuildContext context, String label, double aspectRatio) {
    return ListTile(
      leading: const Icon(Icons.crop),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _applyCrop(aspectRatio);
      },
    );
  }

  Future<void> _applyCrop(double aspectRatio) async {
    if (_selectedCellId == null) return;

    final cellIndex = _currentLayout.cells.indexWhere((c) => c.id == _selectedCellId);
    if (cellIndex == -1) return;

    final cell = _currentLayout.cells[cellIndex];
    final image = _getImageForCell(cell);

    if (image == null) return;

    if (aspectRatio == 0) {
      final cropAspectRatio = cell.height > 0 ? cell.width / cell.height : 1.0;
      final result = await Navigator.of(context).push<FreeCropResult>(
        MaterialPageRoute(
          builder: (context) => FreeCropFullScreen(
            image: image,
            aspectRatio: cropAspectRatio,
            initialScale: cell.scale,
            initialOffsetX: cell.imageOffsetX,
            initialOffsetY: cell.imageOffsetY,
          ),
        ),
      );
      if (result == null) return;

      final normalizedOffsetX = result.offsetX.clamp(-0.5, 0.5);
      final normalizedOffsetY = result.offsetY.clamp(-0.5, 0.5);
      final clampedScale = result.scale.clamp(0.5, 4.0);

      final updatedCell = cell.copyWith(
        scale: clampedScale,
        imageOffsetX: normalizedOffsetX,
        imageOffsetY: normalizedOffsetY,
      );
      final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
      updatedCells[cellIndex] = updatedCell;

      setState(() {
        _currentLayout = _currentLayout.copyWith(cells: updatedCells);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free crop applied from full-screen view'),
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    // Fixed aspect ratio crop
    double newScale = cell.scale;
    final cellAspectRatio = cell.width / cell.height;

    if (cellAspectRatio > aspectRatio) {
      newScale = 1.2;
    } else {
      newScale = 1.2;
    }

    final updatedCell = cell.copyWith(
      scale: newScale,
      imageOffsetX: 0.0,
      imageOffsetY: 0.0,
    );
    final updatedCells = List<LayoutCell>.from(_currentLayout.cells);
    updatedCells[cellIndex] = updatedCell;

    setState(() {
      _currentLayout = _currentLayout.copyWith(cells: updatedCells);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${aspectRatio.toStringAsFixed(2)} aspect ratio'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _FreestyleCell extends StatelessWidget {
  final LayoutCell cell;
  final ImageItem? image;
  final Size canvasSize;
  final bool isSelected;
  final bool isInFreeCropMode;
  final VoidCallback onTap;
  final Function(DragStartDetails) onDragStart;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails) onDragEnd;
  final Function(DragStartDetails, String cornerId) onResizeStart;
  final Function(DragUpdateDetails, String cornerId) onResizeUpdate;
  final Function(DragEndDetails) onResizeEnd;

  const _FreestyleCell({
    required this.cell,
    this.image,
    required this.canvasSize,
    required this.isSelected,
    this.isInFreeCropMode = false,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
  });

  Widget _buildCornerHandle(String cornerId, Offset position, Color color) {
    return Positioned(
      left: position.dx - 12,
      top: position.dy - 12,
      width: 24,
      height: 24,
      child: GestureDetector(
        onPanStart: (details) => onResizeStart(details, cornerId),
        onPanUpdate: (details) => onResizeUpdate(details, cornerId),
        onPanEnd: onResizeEnd,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.open_with,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cellWidth = cell.width * canvasSize.width;
    final cellHeight = cell.height * canvasSize.height;
    final cellX = cell.x * canvasSize.width;
    final cellY = cell.y * canvasSize.height;

    // Calculate image offset in pixels based on normalized offsets
    final offsetX = cell.imageOffsetX * cellWidth;
    final offsetY = cell.imageOffsetY * cellHeight;

    final borderColor = isInFreeCropMode ? Colors.orange : Colors.blue;
    final handleColor = isInFreeCropMode ? Colors.orange : Colors.blue;

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
                ? Border.all(color: borderColor, width: isInFreeCropMode ? 3 : 2)
                : null,
          ),
          child: ClipRRect(
            borderRadius: isSelected ? BorderRadius.circular(4) : BorderRadius.zero,
            child: Stack(
              children: [
                // Image with offset for free crop
                Transform.translate(
                  offset: Offset(offsetX, offsetY),
                  child: Transform.rotate(
                    angle: cell.rotation * math.pi / 180,
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: cell.scale,
                      alignment: Alignment.center,
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
                ),

                // Selection controls
                if (isSelected) ...[
                  // Free crop indicator
                  if (isInFreeCropMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FREE CROP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Corner handles for resizing (only in free crop mode)
                  if (isInFreeCropMode) ...[
                    // Top-left
                    _buildCornerHandle('tl', const Offset(0, 0), handleColor),
                    // Top-right
                    _buildCornerHandle('tr', Offset(cellWidth, 0), handleColor),
                    // Bottom-left
                    _buildCornerHandle('bl', Offset(0, cellHeight), handleColor),
                    // Bottom-right
                    _buildCornerHandle('br', Offset(cellWidth, cellHeight), handleColor),
                  ],
                  
                  // Resize handle (bottom-right corner) - only in normal mode
                  if (!isInFreeCropMode)
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: GestureDetector(
                        onPanStart: (details) => onResizeStart(details, 'br'),
                        onPanUpdate: (details) => onResizeUpdate(details, 'br'),
                        onPanEnd: onResizeEnd,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: handleColor,
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

class FreeCropResult {
  final double scale;
  final double offsetX;
  final double offsetY;

  const FreeCropResult({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

class FreeCropFullScreen extends StatefulWidget {
  final ImageItem image;
  final double aspectRatio;
  final double initialScale;
  final double initialOffsetX;
  final double initialOffsetY;

  const FreeCropFullScreen({
    super.key,
    required this.image,
    required this.aspectRatio,
    required this.initialScale,
    required this.initialOffsetX,
    required this.initialOffsetY,
  });

  @override
  State<FreeCropFullScreen> createState() => _FreeCropFullScreenState();
}

class _FreeCropFullScreenState extends State<FreeCropFullScreen> {
  late final double _initialScale;
  late final double _initialOffsetX;
  late final double _initialOffsetY;

  late double _scale;
  late double _normalizedOffsetX;
  late double _normalizedOffsetY;

  @override
  void initState() {
    super.initState();
    _initialScale = widget.initialScale.clamp(0.5, 4.0);
    _initialOffsetX = widget.initialOffsetX;
    _initialOffsetY = widget.initialOffsetY;
    _scale = _initialScale;
    _normalizedOffsetX = _initialOffsetX;
    _normalizedOffsetY = _initialOffsetY;
  }

  void _applyPan(DragUpdateDetails details, Size frameSize) {
    if (frameSize.width <= 0 || frameSize.height <= 0) return;
    setState(() {
      _normalizedOffsetX = (_normalizedOffsetX + details.delta.dx / frameSize.width).clamp(-1.0, 1.0);
      _normalizedOffsetY = (_normalizedOffsetY + details.delta.dy / frameSize.height).clamp(-1.0, 1.0);
    });
  }

  void _reset() {
    setState(() {
      _scale = _initialScale;
      _normalizedOffsetX = _initialOffsetX;
      _normalizedOffsetY = _initialOffsetY;
    });
  }

  Widget _buildCropImage(Size size) {
    final imageWidget = kIsWeb && widget.image.bytes != null
        ? Image.memory(
            widget.image.bytes!,
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
          )
        : Image.file(
            File(widget.image.path),
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
          );

    return SizedBox(width: size.width, height: size.height, child: imageWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aspectRatio = widget.aspectRatio > 0 ? widget.aspectRatio : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Crop'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Apply'),
              onPressed: () {
                Navigator.of(context).pop(FreeCropResult(
                  scale: _scale,
                  offsetX: _normalizedOffsetX,
                  offsetY: _normalizedOffsetY,
                ));
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Drag to reposition and use the slider to zoom for precise cropping.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final frameSize = Size(constraints.maxWidth, constraints.maxHeight);
                        final translation = Offset(
                          _normalizedOffsetX * frameSize.width,
                          _normalizedOffsetY * frameSize.height,
                        );
                        return GestureDetector(
                          onPanUpdate: (details) => _applyPan(details, frameSize),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  Transform.translate(
                                    offset: translation,
                                    child: Transform.scale(
                                      scale: _scale,
                                      alignment: Alignment.center,
                                      child: _buildCropImage(frameSize),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white70,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                      Text(
                        'Scale ${_scale.toStringAsFixed(2)}×',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  Slider(
                    min: 0.5,
                    max: 4.0,
                    divisions: 70,
                    value: _scale,
                    label: '${_scale.toStringAsFixed(2)}×',
                    onChanged: (value) => setState(() => _scale = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
