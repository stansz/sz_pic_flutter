import 'dart:io';
import 'package:flutter/material.dart';
import '../models/image_comparison.dart';

/// Custom clipper for revealing portions of after image
class _ImageClipper extends CustomClipper<Rect> {
  final double position;

  _ImageClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_ImageClipper oldClipper) {
    return oldClipper.position != position;
  }
}

/// Native Flutter widget for before/after image comparison with slider
///
/// Features:
/// - Stack-based layout with two images
/// - ClipRect for revealing portions
/// - GestureDetector for drag interactions
/// - Animated slider handle
/// - Optional labels
/// - Smooth 60fps performance
/// - Material Design 3 styling
class ImageComparisonSlider extends StatefulWidget {
  /// Comparison configuration
  final ImageComparison comparison;

  /// Callback when slider position changes
  final ValueChanged<double>? onSliderChange;

  /// Height of comparison widget
  final double height;

  /// Whether slider is interactive
  final bool interactive;

  /// Optional filter to apply to after image
  final ColorFilter? afterImageFilter;

  const ImageComparisonSlider({
    super.key,
    required this.comparison,
    this.onSliderChange,
    this.height = 300,
    this.interactive = true,
    this.afterImageFilter,
  });

  @override
  State<ImageComparisonSlider> createState() => _ImageComparisonSliderState();
}

class _ImageComparisonSliderState extends State<ImageComparisonSlider> {
  double _sliderPosition = 0.5;
  double _dragStartX = 0;
  double _dragStartPosition = 0;

  @override
  void initState() {
    super.initState();
    _sliderPosition = widget.comparison.sliderPosition;
  }

  void _setSlider(double position) {
    setState(() {
      _sliderPosition = position.clamp(0.0, 1.0);
    });
    widget.onSliderChange?.call(_sliderPosition);
  }

  Widget _buildImage(String imagePath, {ColorFilter? filter}) {
    Widget imageWidget;
    
    // For web, use Image.network or Image.memory depending on path
    // For native, use Image.file
    if (imagePath.startsWith('http')) {
      imageWidget = Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
        },
      );
    } else if (imagePath.startsWith('data:') || imagePath.startsWith('blob:')) {
      // Web blob or data URL
      imageWidget = Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
        },
      );
    } else {
      // File path for native platforms
      imageWidget = Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
        },
      );
    }
    
    // Apply filter if provided
    if (filter != null) {
      return ColorFiltered(colorFilter: filter, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildSliderHandle() {
    return GestureDetector(
      onHorizontalDragStart: widget.interactive
          ? (details) {
              _dragStartX = details.globalPosition.dx;
              _dragStartPosition = _sliderPosition;
            }
          : null,
      onHorizontalDragUpdate: widget.interactive
          ? (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final size = box.size;
              final delta = details.globalPosition.dx - _dragStartX;
              final positionDelta = delta / size.width;
              _setSlider(_dragStartPosition + positionDelta);
            }
          : null,
      onTapDown: widget.interactive
          ? (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final size = box.size;
              final localPosition = box.globalToLocal(details.globalPosition);
              _setSlider(localPosition.dx / size.width);
            }
          : null,
      child: Container(
        width: widget.comparison.sliderWidth + 20,
        height: double.infinity,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: widget.comparison.sliderWidth,
            decoration: BoxDecoration(
              color: widget.comparison.sliderColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabels() {
    return Stack(
      children: [
        // Before label (left side)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.comparison.beforeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        // After label (right side)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.comparison.afterLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Before image (bottom layer)
          Positioned.fill(
            child: _buildImage(widget.comparison.beforeImagePath),
          ),
          // After image (top layer, clipped)
          Positioned.fill(
            child: ClipRect(
              clipper: _ImageClipper(_sliderPosition),
              child: _buildImage(
                widget.comparison.afterImagePath,
                filter: widget.afterImageFilter,
              ),
            ),
          ),
          // Slider handle
          Positioned(
            left: _sliderPosition * MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            child: _buildSliderHandle(),
          ),
          // Labels (optional)
          if (widget.comparison.showLabels) _buildLabels(),
        ],
      ),
    );
  }
}
