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

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Flutter widget for before/after image comparison on web platform
///
/// Uses native Flutter widgets with Stack and ClipRect for smooth performance
/// Provides touch-friendly slider with mouse and touch support
class WebImageComparison extends StatefulWidget {
  /// Path to before image (original) - can be file path or data URL
  final String beforeImagePath;

  /// Path to after image (filtered/edited) - can be file path or data URL
  final String afterImagePath;

  /// Label text for before image
  final String beforeLabel;

  /// Label text for after image
  final String afterLabel;

  /// Initial slider position (0.0 to 1.0)
  final double initialPosition;

  const WebImageComparison({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.initialPosition = 0.5,
  });

  @override
  State<WebImageComparison> createState() => _WebImageComparisonState();
}

class _WebImageComparisonState extends State<WebImageComparison> {
  double _sliderPosition = 0.5;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _sliderPosition = widget.initialPosition;
  }

  void _updateSliderPosition(double dx, double width) {
    setState(() {
      _sliderPosition = (dx / width).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Fallback for non-web platforms (shouldn't happen but just in case)
      return const Center(
        child: Text(
          'WebImageComparison is only available on web platform',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isDragging = true;
            });
            _updateSliderPosition(details.localPosition.dx, constraints.maxWidth);
          },
          onPanUpdate: (details) {
            if (_isDragging) {
              _updateSliderPosition(details.localPosition.dx, constraints.maxWidth);
            }
          },
          onPanEnd: (_) {
            setState(() {
              _isDragging = false;
            });
          },
          onTapDown: (details) {
            _updateSliderPosition(details.localPosition.dx, constraints.maxWidth);
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // Before image (bottom layer - original)
                _buildImage(widget.beforeImagePath),
                
                // After image (top layer - filtered, clipped)
                ClipRect(
                  clipper: _SliderClipper(_sliderPosition),
                  child: _buildImage(widget.afterImagePath),
                ),
                
                // Slider line
                Positioned(
                  left: _sliderPosition * constraints.maxWidth,
                  top: 0,
                  bottom: 0,
                  child: _buildSlider(),
                ),
                
                // Labels
                Positioned(
                  top: 20,
                  left: 20,
                  child: _buildLabel(widget.beforeLabel),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: _buildLabel(widget.afterLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(String imagePath) {
    final isDataUrl = imagePath.startsWith('data:');
    
    // For web, use NetworkImage for data URLs
    // For file paths, also use NetworkImage (shouldn't happen on web)
    final imageProvider = NetworkImage(imagePath);

    return Image(
      image: imageProvider,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        print('Image load error for: ${imagePath.substring(0, 50)}...');
        print('Error: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildSlider() {
    return Container(
      width: 4,
      color: Colors.white,
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.compare_arrows,
            color: Colors.black54,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Custom clipper that clips based on slider position
class _SliderClipper extends CustomClipper<Rect> {
  final double position;

  _SliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) {
    return oldClipper.position != position;
  }
}
