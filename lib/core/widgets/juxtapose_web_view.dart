import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';

/// WebView widget for before/after image comparison on web platform
///
/// Uses a custom HTML/JS implementation inspired by Juxtapose.js
/// Provides touch-friendly slider with mouse and touch support
class JuxtaposeWebView extends StatefulWidget {
  /// Path to before image (original)
  final String beforeImagePath;

  /// Path to after image (filtered/edited)
  final String afterImagePath;

  /// Label text for before image
  final String beforeLabel;

  /// Label text for after image
  final String afterLabel;

  /// Initial slider position (0.0 to 1.0)
  final double initialPosition;

  const JuxtaposeWebView({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.initialPosition = 0.5,
  });

  @override
  State<JuxtaposeWebView> createState() => _JuxtaposeWebViewState();
}

class _JuxtaposeWebViewState extends State<JuxtaposeWebView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_generateHtml());
  }

  String _generateHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Image Comparison</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      overflow: hidden;
      background: #000;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    
    .juxtapose {
      position: relative;
      width: 100vw;
      height: 100vh;
      overflow: hidden;
    }
    
    .image-container {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .before-image {
      z-index: 1;
    }
    
    .after-image {
      z-index: 2;
      overflow: hidden;
    }
    
    .image-container img {
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
      display: block;
    }
    
    .slider {
      position: absolute;
      top: 0;
      bottom: 0;
      width: 4px;
      background: white;
      cursor: ew-resize;
      z-index: 10;
      box-shadow: 0 0 10px rgba(0,0,0,0.5);
      transition: box-shadow 0.2s ease;
    }
    
    .slider:hover {
      box-shadow: 0 0 15px rgba(0,0,0,0.7);
    }
    
    .slider-handle {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 40px;
      height: 40px;
      background: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 2px 10px rgba(0,0,0,0.3);
      cursor: grab;
    }
    
    .slider-handle:active {
      cursor: grabbing;
      transform: translate(-50%, -50%) scale(1.1);
    }
    
    .slider-handle svg {
      width: 24px;
      height: 24px;
    }
    
    .label {
      position: absolute;
      top: 20px;
      padding: 8px 16px;
      background: rgba(0,0,0,0.7);
      color: white;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 14px;
      font-weight: 500;
      border-radius: 4px;
      z-index: 5;
      backdrop-filter: blur(4px);
      -webkit-backdrop-filter: blur(4px);
      user-select: none;
      pointer-events: none;
    }
    
    .before-label {
      left: 20px;
    }
    
    .after-label {
      right: 20px;
    }
  </style>
</head>
<body>
  <div class="juxtapose" id="juxtapose">
    <div class="image-container before-image">
      <img src="${widget.beforeImagePath}" alt="Before" id="beforeImg">
      <div class="label before-label">${widget.beforeLabel}</div>
    </div>
    <div class="image-container after-image" id="afterContainer" style="width: ${widget.initialPosition * 100}%">
      <img src="${widget.afterImagePath}" alt="After" id="afterImg">
      <div class="label after-label">${widget.afterLabel}</div>
    </div>
    <div class="slider" id="slider" style="left: ${widget.initialPosition * 100}%">
      <div class="slider-handle">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#333" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M15 18l-6-6 6-6"/>
          <path d="M9 18l6-6-6-6"/>
        </svg>
      </div>
    </div>
  </div>
  <script>
    const slider = document.getElementById('slider');
    const afterContainer = document.getElementById('afterContainer');
    const juxtapose = document.getElementById('juxtapose');
    let isDragging = false;
    let isTouching = false;

    function updateSlider(x) {
      const rect = juxtapose.getBoundingClientRect();
      let position = (x - rect.left) / rect.width;
      position = Math.max(0, Math.min(1, position));
      slider.style.left = (position * 100) + '%';
      afterContainer.style.width = (position * 100) + '%';
    }

    // Mouse events
    slider.addEventListener('mousedown', (e) => {
      isDragging = true;
      e.preventDefault();
      e.stopPropagation();
    });

    document.addEventListener('mousemove', (e) => {
      if (isDragging && !isTouching) {
        updateSlider(e.clientX);
      }
    });

    document.addEventListener('mouseup', () => {
      isDragging = false;
    });

    // Touch events
    slider.addEventListener('touchstart', (e) => {
      isDragging = true;
      isTouching = true;
      e.preventDefault();
      e.stopPropagation();
    }, { passive: false });

    document.addEventListener('touchmove', (e) => {
      if (isDragging && isTouching) {
        updateSlider(e.touches[0].clientX);
        e.preventDefault();
      }
    }, { passive: false });

    document.addEventListener('touchend', () => {
      isDragging = false;
      isTouching = false;
    });

    // Handle window resize
    window.addEventListener('resize', () => {
      // Re-center if needed
    });

    // Prevent scroll on touch devices when dragging slider
    juxtapose.addEventListener('touchmove', (e) => {
      if (isDragging) {
        e.preventDefault();
      }
    }, { passive: false });
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Fallback for non-web platforms (shouldn't happen but just in case)
      return const Center(
        child: Text(
          'WebView is only available on web platform',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return WebViewWidget(controller: _controller);
  }
}
