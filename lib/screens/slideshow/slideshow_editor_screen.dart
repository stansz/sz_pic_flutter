import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../../core/models/image_item.dart';
import '../../core/models/slideshow_models.dart';
import '../../core/services/slideshow_engine.dart';
import '../../core/utils/export_helper.dart';
import '../../core/widgets/image_item_widget.dart';

enum SlideshowExportFormat { pngSequence, video, projectFile }

extension on SlideshowExportFormat {
  String get displayName {
    switch (this) {
      case SlideshowExportFormat.pngSequence:
        return 'PNG Sequence';
      case SlideshowExportFormat.video:
        return 'Video (MP4)';
      case SlideshowExportFormat.projectFile:
        return 'Project File';
    }
  }
  
  String get description {
    switch (this) {
      case SlideshowExportFormat.pngSequence:
        return 'Individual slide images';
      case SlideshowExportFormat.video:
        return 'Compiled MP4 with transitions';
      case SlideshowExportFormat.projectFile:
        return 'Save project for later editing';
    }
  }
}

class SlideshowEditorScreen extends StatefulWidget {
  final SlideshowProject project;

  const SlideshowEditorScreen({
    super.key,
    required this.project,
  });

  @override
  State<SlideshowEditorScreen> createState() => _SlideshowEditorScreenState();
}

class _SlideshowEditorScreenState extends State<SlideshowEditorScreen>
    with SingleTickerProviderStateMixin {
  late SlideshowProject _project;
  int _currentSlideIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  Duration _remainingTime = Duration.zero;
  late TransitionType _activeTransitionType;
  int? _previousSlideIndex;
  late AnimationController _transitionController;
  final GlobalKey _slideshowKey = GlobalKey();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _remainingTime = _project.slides.isNotEmpty
        ? _project.slides[0].duration
        : Duration.zero;
    _activeTransitionType = _sanitizeTransitionType(
      _project.slides.isNotEmpty ? _project.slides[0].transitionIn?.type : null,
    );
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..value = 1.0
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _previousSlideIndex != null) {
          setState(() {
            _previousSlideIndex = null;
          });
        }
      });
  }

  @override
  void dispose() {
    _stopPlayback();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note_rounded),
            onPressed: _showMusicOptions,
            tooltip: 'Add Music',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
          if (!kIsWeb)
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              onPressed: _isExporting ? null : _saveProject,
              tooltip: 'Export',
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
        top: false,
        bottom: true,
        child: Column(
          children: [
            // Slideshow Preview
            Expanded(
              child: _buildPreview(context),
            ),

            // Progress Indicator
            _buildProgressIndicator(context),

            // Controls
            _buildControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (_project.slides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No slides',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          key: _slideshowKey,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildTransitionStack(),

                // Slide Counter and Timer Overlay
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_remainingTime.inSeconds}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransitionStack() {
    final currentSlide = _project.slides[_currentSlideIndex];
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        final progress = _transitionController.value.clamp(0.0, 1.0);
        final slides = <Widget>[];
        if (_previousSlideIndex != null &&
            _previousSlideIndex! >= 0 &&
            _previousSlideIndex! < _project.slides.length) {
          slides.add(_buildTransitionedSlide(
            _project.slides[_previousSlideIndex!],
            progress,
            incoming: false,
          ));
        }
        slides.add(_buildTransitionedSlide(currentSlide, progress, incoming: true));
        return Stack(
          fit: StackFit.expand,
          children: slides,
        );
      },
    );
  }

  Widget _buildTransitionedSlide(Slide slide, double progress, {required bool incoming}) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final effectProgress = incoming ? clampedProgress : 1.0 - clampedProgress;
    final transitionType = slide.transitionIn?.type ?? _activeTransitionType;
    Widget child = _buildSlideImage(slide);
    switch (transitionType) {
      case TransitionType.slide:
        final translation = incoming
            ? Offset(1.0 - clampedProgress, 0)
            : Offset(-clampedProgress, 0);
        child = FractionalTranslation(
          translation: translation,
          child: child,
        );
        break;
      case TransitionType.zoom:
        final scaleValue = incoming
            ? 0.8 + 0.2 * effectProgress
            : 1.0 + 0.15 * clampedProgress;
        child = Transform.scale(
          scale: scaleValue,
          alignment: Alignment.center,
          child: child,
        );
        break;
      case TransitionType.kenBurns:
        final scaleValue = 1.0 + (incoming ? 0.05 * effectProgress : 0.05 * clampedProgress);
        final translation = incoming
            ? Offset(0.05 * (1 - effectProgress), 0.05 * (1 - effectProgress))
            : Offset(-0.05 * clampedProgress, -0.05 * clampedProgress);
        child = FractionalTranslation(
          translation: translation,
          child: Transform.scale(
            scale: scaleValue,
            alignment: Alignment.center,
            child: child,
          ),
        );
        break;
      case TransitionType.fade:
      case TransitionType.dissolve:
        // No additional transform, fallback to opacity only
        break;
    }
    final opacity = incoming ? clampedProgress : 1.0 - clampedProgress;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: child,
    );
  }

  Widget _buildSlideImage(Slide slide) {
    return FittedBox(
      fit: BoxFit.contain,
      child: ImageItemWidget(
        image: slide.image,
        key: ValueKey(slide.id),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _project.slides.asMap().entries.map((entry) {
          final index = entry.key;
          final isPast = index < _currentSlideIndex;

          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isPast
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: _currentSlideIndex > 0 ? _previousSlide : null,
            iconSize: 32,
          ),

          // Play/Pause
          FloatingActionButton.small(
            onPressed: _togglePlayback,
            child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),

          // Next
          IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: _currentSlideIndex < _project.slides.length - 1
                ? _nextSlide
                : null,
            iconSize: 32,
          ),

          // Shuffle
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: _shuffleSlides,
            tooltip: 'Shuffle',
          ),
        ],
      ),
    );
  }

  void _goToSlide(int index, {bool animate = true}) {
    if (_project.slides.isEmpty) return;
    if (index < 0 || index >= _project.slides.length) return;
    if (index == _currentSlideIndex) return;
    final previousIndex = _currentSlideIndex;
    setState(() {
      _previousSlideIndex = animate ? previousIndex : null;
      _currentSlideIndex = index;
      _remainingTime = _project.slides[index].duration;
    });
    if (animate) {
      _runTransitionAnimation(_project.slides[index]);
    } else {
      _transitionController.value = 1.0;
    }
  }

  void _runTransitionAnimation(Slide slide) {
    final duration = slide.transitionIn?.duration ?? const Duration(milliseconds: 500);
    _transitionController
      ..duration = duration
      ..forward(from: 0.0);
  }

  TransitionType _sanitizeTransitionType(TransitionType? type) {
    if (type == TransitionType.dissolve) {
      return TransitionType.fade;
    }
    return type ?? TransitionType.fade;
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_project.slides.isEmpty) return;

    setState(() {
      _isPlaying = true;
    });

    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingTime.inMilliseconds > 100) {
          setState(() {
            _remainingTime = _remainingTime - const Duration(milliseconds: 100);
          });
        } else {
          if (_currentSlideIndex < _project.slides.length - 1) {
            _goToSlide(_currentSlideIndex + 1);
          } else {
            _stopPlayback();
            _goToSlide(0, animate: false);
          }
        }
      },
    );
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    setState(() {
      _isPlaying = false;
    });
  }

  void _previousSlide() {
    _stopPlayback();
    _goToSlide(_currentSlideIndex - 1);
  }

  void _nextSlide() {
    _stopPlayback();
    _goToSlide(_currentSlideIndex + 1);
  }

  void _shuffleSlides() {
    final engine = SlideshowEngine();
    final shuffledImages = List<ImageItem>.from(
      _project.slides.map((slide) => slide.image),
    )..shuffle();

    final newProject = engine.createSlideshow(
      images: shuffledImages,
      slideDuration: _project.slides.isNotEmpty
          ? _project.slides[0].duration
          : const Duration(seconds: 3),
      transitionType: _project.slides.isNotEmpty
          ? _project.slides[0].transitionIn?.type
          : TransitionType.fade,
    );

    setState(() {
      _project = newProject;
      _activeTransitionType = _project.slides.isNotEmpty
          ? _sanitizeTransitionType(_project.slides[0].transitionIn?.type)
          : _activeTransitionType;
      _currentSlideIndex = 0;
      _remainingTime = _project.slides.isNotEmpty
          ? _project.slides[0].duration
          : Duration.zero;
      _previousSlideIndex = null;
      _transitionController.value = 1.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Slides shuffled'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showMusicOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.music_note_rounded),
              title: const Text('Add Music'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement music picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Music feature coming soon'),
                  ),
                );
              },
            ),
            if (_project.musicPath != null)
              ListTile(
                leading: const Icon(Icons.music_off_rounded),
                title: const Text('Remove Music'),
                onTap: () {
                  setState(() {
                    _project = SlideshowEngine().removeMusic(_project);
                  });
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).viewPadding.bottom;
          return Padding(
            padding: EdgeInsets.only(
              bottom: bottomInset + 16,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Slideshow Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_rounded),
                          tooltip: 'Done',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Slide Duration
                    Row(
                      children: [
                        const Text('Slide Duration'),
                        const Spacer(),
                        Text(
                          '${_project.slides.isNotEmpty ? _project.slides[0].duration.inSeconds : 3}s',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _project.slides.isNotEmpty
                          ? _project.slides[0].duration.inSeconds.toDouble()
                          : 3.0,
                      min: 1,
                      max: 15,
                      divisions: 14,
                      onChanged: (value) {
                        final newDuration = Duration(seconds: value.toInt());
                        final newProject = SlideshowEngine().updateSlideDuration(
                          _project,
                          newDuration,
                        );
                        setState(() {
                          _project = newProject;
                          // Update remaining time to match new duration for current slide
                          if (_project.slides.isNotEmpty) {
                            _remainingTime = _project.slides[_currentSlideIndex].duration;
                          }
                        });
                        // Also update the modal state to rebuild the bottom sheet
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Transition Type
                    Row(
                      children: [
                        const Text('Transition'),
                        const Spacer(),
                        DropdownButton<TransitionType>(
                          value: _activeTransitionType,
                          underline: const SizedBox(),
                          onChanged: (value) {
                            if (value != null) {
                              final newProject =
                                  SlideshowEngine().updateTransitionType(
                                _project,
                                value,
                                const Duration(milliseconds: 500),
                              );
                              setState(() {
                                _project = newProject;
                                _activeTransitionType = value;
                              });
                              // Also update the modal state to rebuild the bottom sheet
                              setModalState(() {});
                            }
                          },
                          items: TransitionType.values
                              .where((type) => type != TransitionType.dissolve)
                              .map((type) {
                            final name = type.name;
                            final displayName = name.isEmpty
                                ? name
                                : name[0].toUpperCase() + name.substring(1);
                            return DropdownMenuItem(
                              value: type,
                              child: Text(displayName),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List> _captureCurrentSlide() async {
    final RenderRepaintBoundary boundary =
        _slideshowKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _ensureSlideImageReady(Slide slide, int index) async {
    final imageFile = File(slide.image.path);
    final exists = await imageFile.exists();
    final fileSize = exists ? await imageFile.length() : 0;
    if (!exists) {
      debugPrint('[exportVideo] slide $index image missing at ${slide.image.path}');
      return;
    }
    debugPrint('[exportVideo] precache slide index=$index path=${slide.image.path} size=$fileSize');
    try {
      await precacheImage(FileImage(imageFile), context);
    } catch (e) {
      debugPrint('[exportVideo] precache failed for index=$index path=${slide.image.path}: $e');
    }
  }

  Future<void> _waitForNextFrame() async {
    // Allow the widget tree to rebuild and the image to paint
    await Future.delayed(const Duration(milliseconds: 80));
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 40));
  }

  Future<void> _exportSlideshow(SlideshowExportFormat format) async {
    setState(() {
      _isExporting = true;
    });

    try {
      switch (format) {
        case SlideshowExportFormat.pngSequence:
          await _exportPngSequence();
          break;
        case SlideshowExportFormat.video:
          await _exportVideo();
          break;
        case SlideshowExportFormat.projectFile:
          await _exportProjectFile();
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
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

  Future<void> _exportPngSequence() async {
    if (_project.slides.isEmpty) {
      throw StateError('No slides to export');
    }

    // Prompt user for a save directory
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to save slideshow slides',
      lockParentWindow: true,
    );

    if (selectedDirectory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PNG sequence export canceled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Save each slide as a PNG image
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    int savedCount = 0;

    for (int i = 0; i < _project.slides.length; i++) {
      // Navigate to each slide without animation
      _goToSlide(i, animate: false);
      
      // Wait for the slide to render
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Capture the current slide
      final bytes = await _captureCurrentSlide();
      
      // Save the image
      final fileName = 'slide_${i + 1}_of_${_project.slides.length}_$timestamp.png';
      final filePath = p.join(selectedDirectory, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      savedCount++;
    }

    // Return to the original slide
    _goToSlide(_currentSlideIndex, animate: false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount slides saved to: $selectedDirectory'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _exportVideo() async {
    if (_project.slides.isEmpty) {
      throw StateError('No slides to export');
    }

    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video export is not supported on the web yet.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to save slideshow frames + manifest',
      lockParentWindow: true,
    );

    if (selectedDirectory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video export canceled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _stopPlayback();
    final originalIndex = _currentSlideIndex;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final exportDir = Directory(
      p.join(selectedDirectory, 'slideshow_frames_$timestamp'),
    );
    await exportDir.create(recursive: true);
    final frameFiles = <File>[];

    try {
      for (var i = 0; i < _project.slides.length; i++) {
        _goToSlide(i, animate: false);
        final slide = _project.slides[i];
        await _ensureSlideImageReady(slide, i);
        await _waitForNextFrame();
        final bytes = await _captureCurrentSlide();
        final frameFile = File(
          p.join(exportDir.path, 'frame_${i.toString().padLeft(4, '0')}.png'),
        );
        await frameFile.writeAsBytes(bytes);
        final frameExists = await frameFile.exists();
        final frameSize = frameExists ? await frameFile.length() : 0;
        debugPrint(
          '[exportVideo] captured frame index=$i slideId=${slide.id} durationMs=${slide.duration.inMilliseconds} bytes=${bytes.length} fileExists=$frameExists fileSize=$frameSize path=${frameFile.path}',
        );
        frameFiles.add(frameFile);
      }

      final listFile = File(p.join(exportDir.path, 'frames.txt'));
      final buffer = StringBuffer();
      for (var i = 0; i < frameFiles.length; i++) {
        final slide = _project.slides[i];
        buffer.writeln("file '${_escapePathForConcat(frameFiles[i].path)}'");
        final durationSeconds = slide.duration.inMilliseconds / 1000.0;
        buffer.writeln('duration ${durationSeconds.toStringAsFixed(3)}');
      }
      final listContents = buffer.toString();
      await listFile.writeAsString(listContents);
      debugPrint('[exportVideo] frames manifest path=${listFile.path}\n$listContents');

      final outputPath = p.join(selectedDirectory, 'slideshow_$timestamp.mp4');
      final ffmpegCommand = [
        '-y',
        '-f concat',
        '-safe 0',
        '-i "${listFile.path}"',
        '-fps_mode vfr',
        '-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2"',
        '-pix_fmt yuv420p',
        '-c:v libx264',
        '-preset veryfast',
        '-crf 20',
        '-movflags +faststart',
        '"$outputPath"',
      ].join(' ');
      debugPrint('[exportVideo] running ffmpeg: $ffmpegCommand');

      final session = await FFmpegKit.execute(ffmpegCommand);

      final returnCode = await session.getReturnCode();
      final sessionState = await session.getState();
      final sessionDurationMs = await session.getDuration();
      final ffmpegLogs = await session.getAllLogsAsString(5000);
      debugPrint('FFmpeg exit=${returnCode?.getValue()} state=$sessionState duration=${sessionDurationMs}ms');

      if (!ReturnCode.isSuccess(returnCode)) {
        final failStack = await session.getFailStackTrace();
        final stderrOutput = await session.getOutput();
        debugPrint('FFmpeg command failed: $ffmpegCommand');
        debugPrint('FFmpeg logs:\n${ffmpegLogs ?? stderrOutput ?? 'no logs'}');
        throw Exception(
          'FFmpeg failed (code ${returnCode?.getValue()}): ${failStack ?? stderrOutput ?? 'see logs'}',
        );
      } else {
        debugPrint('FFmpeg command succeeded: $ffmpegCommand');
        if (ffmpegLogs != null) {
          debugPrint('FFmpeg logs:\n$ffmpegLogs');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video exported to: $outputPath'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted && _project.slides.isNotEmpty) {
        _goToSlide(originalIndex, animate: false);
      } else if (_project.slides.isNotEmpty) {
        _currentSlideIndex = originalIndex.clamp(0, _project.slides.length - 1);
        _remainingTime = _project.slides[_currentSlideIndex].duration;
      }
    }
  }

  Future<void> _exportProjectFile() async {
    // For now, save as a JSON file with project data
    final projectJson = {
      'id': _project.id,
      'name': _project.name,
      'createdAt': _project.createdAt.toIso8601String(),
      'updatedAt': _project.updatedAt.toIso8601String(),
      'totalDuration': _project.totalDuration.inMilliseconds,
      'musicPath': _project.musicPath,
      'slides': _project.slides.map((slide) => {
        'id': slide.id,
        'order': slide.order,
        'duration': slide.duration.inMilliseconds,
        'imagePath': slide.image.path,
        'transitionIn': {
          'type': slide.transitionIn?.type.name,
          'duration': slide.transitionIn?.duration.inMilliseconds,
        },
        'transitionOut': {
          'type': slide.transitionOut?.type.name,
          'duration': slide.transitionOut?.duration.inMilliseconds,
        },
      }).toList(),
    };

    final jsonString = JsonEncoder.withIndent('  ').convert(projectJson);
    final bytes = Uint8List.fromList(jsonString.codeUnits);

    if (kIsWeb) {
      final filename = '${_project.name.replaceAll(' ', '_')}_project_${DateTime.now().millisecondsSinceEpoch}.json';
      downloadImage(bytes, filename, 'application/json');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project file download ready: $filename'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Prompt user for a save directory
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to save project file',
      lockParentWindow: true,
    );

    if (selectedDirectory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project file export canceled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final fileName = '${_project.name.replaceAll(' ', '_')}_project_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = p.join(selectedDirectory, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project file saved to: $filePath'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  String _escapePathForConcat(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.replaceAll("'", "\\'");
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Export Slideshow',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(SlideshowExportFormat.video.displayName),
              subtitle: Text(SlideshowExportFormat.video.description),
              onTap: () {
                Navigator.pop(context);
                _exportSlideshow(SlideshowExportFormat.video);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProject() {
    // For now, show export options instead of just a placeholder
    _showExportOptions();
  }
}
