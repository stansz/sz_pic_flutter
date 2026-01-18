import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../../core/models/image_item.dart';
import '../../core/models/slideshow_models.dart';
import '../../core/models/music_track.dart';
import '../../core/services/music_library.dart';
import '../../core/services/music_service.dart';
import '../../core/services/slideshow_engine.dart';
import '../../core/utils/export_helper.dart';
import '../../core/widgets/image_item_widget.dart';
import '../../core/widgets/loading_dialog.dart';

// Platform-specific hardware encoder selection
// Note: Hardware encoders (h264_videotoolbox, h264_vaapi) require specific FFmpeg Kit
// configurations and may not be available on all devices. Defaulting to libx264
// (software encoding) which is always available and reliable.
String _getHardwareEncoder() {
  if (Platform.isIOS || Platform.isMacOS) {
    return 'libx264'; // Use software encoding for maximum compatibility
  } else if (Platform.isAndroid) {
    return 'libx264'; // VAAPI requires specific setup; use software encoding
  } else {
    return 'libx264';
  }
}

// Check if hardware acceleration is likely available
bool _isHardwareAccelerationLikely() {
  if (Platform.isIOS || Platform.isMacOS) {
    return true; // VideoToolbox is always available on Apple devices
  }
  // On Android, hardware encoding availability varies
  return true;
}

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
        return 'Compiled MP4 with transitions (15fps)';
      case SlideshowExportFormat.projectFile:
        return 'Save project for later editing';
    }
  }
}

class _FrameCaptureResult {
  final List<File> files;
  final List<double> durations;
  
  _FrameCaptureResult({required this.files, required this.durations});
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

  // Music
  final MusicService _musicService = MusicService();
  MusicTrack? _selectedTrack;
  double _musicVolume = 0.8;
  Timer? _musicFadeOutTimer;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _selectedTrack = _resolveTrackFromProject(_project.musicPath);
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
    _stopMusic();
    _transitionController.dispose();
    _musicService.dispose();
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

  MusicTrack? _resolveTrackFromProject(String? path) {
    if (path == null) return null;
    try {
      return MusicLibrary.tracks.firstWhere((t) => t.assetPath == path || t.id == path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setSelectedTrack(MusicTrack track) async {
    setState(() {
      _selectedTrack = track;
      _project = SlideshowEngine().addMusic(_project, track.assetPath);
    });
  }

  Future<void> _clearSelectedTrack() async {
    setState(() {
      _selectedTrack = null;
      _project = SlideshowEngine().removeMusic(_project);
    });
    _cancelMusicFadeOut();
    await _musicService.stop();
  }

  Future<void> _playMusicIfSelected() async {
    if (_selectedTrack == null || kIsWeb) return;
    final fadeDuration = _adaptiveMusicFadeDuration;
    _cancelMusicFadeOut();
    final played = await _musicService.playTrack(
      _selectedTrack!,
      initialVolume: 0.0,
    );
    if (!played && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to play ${_selectedTrack!.title}. Check assets/music files.'),
        ),
      );
    } else if (played) {
      _musicService.fadeToVolume(_musicVolume, fadeDuration);
      _scheduleMusicFadeOut(fadeDuration);
    }
  }

  Future<void> _stopMusic() async {
    _cancelMusicFadeOut();
    await _musicService.stop();
  }

  Duration get _adaptiveMusicFadeDuration {
    final totalMs = _project.totalDuration.inMilliseconds;
    const minFadeMs = 1000;
    final candidateMs = max(minFadeMs, (totalMs * 0.25).round());
    final capMs = max(minFadeMs, (totalMs ~/ 2));
    final fadeMs = min(candidateMs, capMs);
    return Duration(milliseconds: fadeMs);
  }

  void _scheduleMusicFadeOut(Duration fadeDuration) {
    _cancelMusicFadeOut();
    final delay = _project.totalDuration - fadeDuration;
    if (delay <= Duration.zero) {
      _musicService.fadeToVolume(0.0, fadeDuration);
      return;
    }
    _musicFadeOutTimer = Timer(delay, () {
      _musicService.fadeToVolume(0.0, fadeDuration);
    });
  }

  void _cancelMusicFadeOut() {
    _musicFadeOutTimer?.cancel();
    _musicFadeOutTimer = null;
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

    _playMusicIfSelected();

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
    _stopMusic();
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
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio playback is disabled on web builds.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 16;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.music_note_rounded),
                    const SizedBox(width: 8),
                    const Text(
                      'Background Music',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Built-in tracks (copyright-free). Tap to select. Attribution is listed below.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: MusicLibrary.tracks.length,
                    itemBuilder: (context, index) {
                      final track = MusicLibrary.tracks[index];
                      final isSelected = _selectedTrack?.id == track.id;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          ),
                          title: Text(track.genre),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow_rounded),
                            onPressed: () {
                              _musicService.playTrack(track);
                            },
                            tooltip: 'Preview',
                          ),
                          onTap: () async {
                            await _setSelectedTrack(track);
                            if (mounted) Navigator.of(context).pop();
                            _playMusicIfSelected();
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Volume'),
                    Expanded(
                      child: Slider(
                        value: _musicVolume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            _musicVolume = value;
                          });
                          _musicService.setVolume(value);
                        },
                      ),
                    ),
                    Text('${(_musicVolume * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 4),
                if (_selectedTrack != null)
                  Text(
                    'Selected: ${_selectedTrack!.title} — ${_selectedTrack!.attributionText}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _selectedTrack != null
                          ? () {
                              _clearSelectedTrack();
                              Navigator.of(context).pop();
                            }
                          : null,
                      icon: const Icon(Icons.music_off_rounded),
                      label: const Text('Remove Music'),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Attribution'),
                            content: Text(
                              'Refer to assets/music/licenses.md for full attribution.\n\n'
                              '${MusicLibrary.tracks.map((t) => '- ${t.attributionText}').join('\n')}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Attribution'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
    
    // Diagnostic: log canvas size and capture parameters
    final canvasSize = boundary.size;
    final startTime = DateTime.now();
    
    // Capture at lower pixel ratio for faster export (diagnostic: try 1.5)
    const pixelRatio = 1.5; // Diagnostic: reduce from 2.0 to 1.5
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final captureTimeMs = DateTime.now().difference(startTime).inMilliseconds;
    
    debugPrint('[exportVideo] frame capture: canvas=${canvasSize.width}x${canvasSize.height} '
        'pixelRatio=$pixelRatio captureTime=${captureTimeMs}ms output=${image.width}x${image.height}');
    
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
    await Future.delayed(const Duration(milliseconds: 50)); // Reduced from 80
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 20)); // Reduced from 40
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
      debugPrint('[exportSlideshow] Export error: $e');
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (snackBarError) {
          debugPrint('[exportSlideshow] Failed to show error SnackBar: $snackBarError');
        }
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
    final frameDurations = <double>[];
try {
  // Add initial delay to let GPU settle before starting export
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Calculate total number of frames to be captured for progress tracking
  int totalFrames = 0;
  const transitionFps = 15; // Reduced from 30 to prevent GPU surface loss
  const slideFps = 5; // Reduced from 10 to prevent GPU surface loss
      const transitionDurationMs = 500; // Default transition duration in milliseconds
      
      // Calculate total frames
      for (var i = 0; i < _project.slides.length; i++) {
        final slide = _project.slides[i];
        final transitionDuration = slide.transitionIn?.duration ?? const Duration(milliseconds: transitionDurationMs);
        
        // Add transition frames (except first slide)
        if (i > 0) {
          final frameIntervalMs = (1000 / transitionFps).round();
          final transitionFrames = (transitionDuration.inMilliseconds / frameIntervalMs).ceil();
          totalFrames += transitionFrames;
        }
        
        // Add static slide frames
        final frameIntervalMs = (1000 / slideFps).round();
        final staticFrames = (slide.duration.inMilliseconds / frameIntervalMs).ceil();
        totalFrames += staticFrames;
      }
      
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LoadingDialog(
          message: 'Exporting slideshow',
          showProgress: true,
          current: 0,
          total: totalFrames,
        ),
      );
      
      int frameIndex = 0;
      
      for (var i = 0; i < _project.slides.length; i++) {
        final slide = _project.slides[i];
        final transitionDuration = slide.transitionIn?.duration ?? const Duration(milliseconds: transitionDurationMs);
        
        // Capture transition frames (except for first slide)
        if (i > 0) {
          debugPrint('[exportVideo] capturing transition from slide ${i-1} to $i');
          final transitionFrames = await _captureTransitionFrames(
            fromIndex: i - 1,
            toIndex: i,
            transitionDuration: transitionDuration,
            fps: transitionFps,
            exportDir: exportDir,
            startFrameIndex: frameIndex,
            totalFrames: totalFrames,
          );
          frameFiles.addAll(transitionFrames.files);
          frameDurations.addAll(transitionFrames.durations);
          frameIndex += transitionFrames.files.length;
        }
        
        // Capture static slide frames
        debugPrint('[exportVideo] capturing static slide $i');
        final staticFrames = await _captureStaticSlideFrames(
          slideIndex: i,
          slideDuration: slide.duration,
          fps: slideFps,
          exportDir: exportDir,
          startFrameIndex: frameIndex,
          totalFrames: totalFrames,
        );
        frameFiles.addAll(staticFrames.files);
        frameDurations.addAll(staticFrames.durations);
        frameIndex += staticFrames.files.length;
      }

      final listFile = File(p.join(exportDir.path, 'frames.txt'));
      final buffer = StringBuffer();
      for (var i = 0; i < frameFiles.length; i++) {
        buffer.writeln("file '${_escapePathForConcat(frameFiles[i].path)}'");
        buffer.writeln('duration ${frameDurations[i].toStringAsFixed(6)}');
      }
      final listContents = buffer.toString();
      await listFile.writeAsString(listContents);
      debugPrint('[exportVideo] frames manifest path=${listFile.path}\n$listContents');
      debugPrint('[exportVideo] total frames captured: ${frameFiles.length}');

      final audioPath = await _materializeSelectedAudioFile();

      final outputPath = p.join(selectedDirectory, 'slideshow_$timestamp.mp4');
      
      // Start timing for FFmpeg encoding phase
      final ffmpegStartTime = DateTime.now();
      
      // Use software encoding (libx264) for maximum compatibility
      final ffmpegCommandParts = <String>[
        '-y',
        '-f concat',
        '-safe 0',
        '-i "${listFile.path}"',
        if (audioPath != null) '-i "$audioPath"',
        '-r 15',
        '-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2"',
        '-pix_fmt yuv420p',
        '-c:v ${_getHardwareEncoder()}',  // Use platform-appropriate hardware encoder
        '-preset ultrafast',  // Faster encoding than veryfast
        '-crf 20',
        if (audioPath != null) ...['-c:a aac', '-b:a 192k', '-shortest'],
        '-movflags +faststart',
        '"$outputPath"',
      ];
      final ffmpegCommand = ffmpegCommandParts.join(' ');
      debugPrint('[exportVideo] FFmpeg command: $ffmpegCommand');
      debugPrint('[exportVideo] Hardware encoder: ${_getHardwareEncoder()}');

      final session = await FFmpegKit.execute(ffmpegCommand);

      final returnCode = await session.getReturnCode();
      final sessionState = await session.getState();
      final sessionDurationMs = await session.getDuration();
      final ffmpegLogs = await session.getAllLogsAsString(5000);
      final ffmpegEncodingTimeMs = DateTime.now().difference(ffmpegStartTime).inMilliseconds;
      debugPrint('FFmpeg exit=${returnCode?.getValue()} state=$sessionState duration=${sessionDurationMs}ms encodingTime=${ffmpegEncodingTimeMs}ms');

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('FFmpeg command succeeded: $ffmpegCommand');
        if (ffmpegLogs != null) {
          debugPrint('FFmpeg logs:\n$ffmpegLogs');
        }

        if (mounted) {
          try {
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
          } catch (e) {
            debugPrint('[exportVideo] Failed to show success SnackBar: $e');
          }
        }
      } else {
        final failStack = await session.getFailStackTrace();
        final stderrOutput = await session.getOutput();
        debugPrint('FFmpeg command failed: $ffmpegCommand');
        debugPrint('FFmpeg logs:\n${ffmpegLogs ?? stderrOutput ?? 'no logs'}');
        throw Exception(
          'FFmpeg failed (code ${returnCode?.getValue()}): ${failStack ?? stderrOutput ?? 'see logs'}',
        );
      }

      // Clean up the temporary frame folder after successful export
      try {
        if (await exportDir.exists()) {
          await exportDir.delete(recursive: true);
          debugPrint('[exportVideo] cleaned up temporary frame folder: ${exportDir.path}');
        }
      } catch (e) {
        debugPrint('[exportVideo] failed to clean up temporary folder: $e');
      }
    } finally {
      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Restore original state
      if (mounted && _project.slides.isNotEmpty) {
        _goToSlide(originalIndex, animate: false);
        _previousSlideIndex = null;
        _transitionController.value = 1.0;
      } else if (_project.slides.isNotEmpty) {
        _currentSlideIndex = originalIndex.clamp(0, _project.slides.length - 1);
        _remainingTime = _project.slides[_currentSlideIndex].duration;
        _previousSlideIndex = null;
        _transitionController.value = 1.0;
      }
    }
  }

  Future<_FrameCaptureResult> _captureTransitionFrames({
    required int fromIndex,
    required int toIndex,
    required Duration transitionDuration,
    required int fps,
    required Directory exportDir,
    required int startFrameIndex,
    required int totalFrames,
  }) async {
    final files = <File>[];
    final durations = <double>[];
    final frameIntervalMs = (1000 / fps).round();
    final transitionFrames = (transitionDuration.inMilliseconds / frameIntervalMs).ceil();
    
    debugPrint('[exportVideo] transition: from=$fromIndex to=$toIndex durationMs=${transitionDuration.inMilliseconds} fps=$fps frames=$transitionFrames');
    
    // Start the transition animation
    _goToSlide(fromIndex, animate: false);
    await _waitForNextFrame();
    
    // Set up for transition
    setState(() {
      _previousSlideIndex = fromIndex;
      _currentSlideIndex = toIndex;
    });
    
    // Run transition animation and capture frames
    final transitionDurationMs = transitionDuration.inMilliseconds;
    for (var i = 0; i < transitionFrames; i++) {
      final progress = (i / transitionFrames).clamp(0.0, 1.0);
      _transitionController.value = progress;
      
      // Wait for the widget to rebuild with the new animation value
      await Future.delayed(const Duration(milliseconds: 30)); // Reduced from 150ms total
      await WidgetsBinding.instance.endOfFrame;
      
      // Capture the frame
      final bytes = await _captureCurrentSlide();
      final frameFile = File(
        p.join(exportDir.path, 'frame_${(startFrameIndex + i).toString().padLeft(4, '0')}.png'),
      );
      
      // Write file asynchronously in parallel (non-blocking)
      _writeFrameFile(frameFile, bytes);
      
      files.add(frameFile);
      durations.add(1.0 / fps);
      
      // Update progress dialog less frequently
      if (mounted && (i % 3 == 0 || i == transitionFrames - 1)) {
        _updateExportProgress(startFrameIndex + i + 1, totalFrames);
      }
      
      debugPrint('[exportVideo] transition frame ${startFrameIndex + i}/$transitionFrames progress=$progress bytes=${bytes.length}');
    }
    
    // Reset transition controller
    _transitionController.value = 1.0;
    setState(() {
      _previousSlideIndex = null;
    });
    
    // Brief delay after transition
    await Future.delayed(const Duration(milliseconds: 30)); // Reduced from 100
    
    return _FrameCaptureResult(files: files, durations: durations);
  }

  Future<_FrameCaptureResult> _captureStaticSlideFrames({
    required int slideIndex,
    required Duration slideDuration,
    required int fps,
    required Directory exportDir,
    required int startFrameIndex,
    required int totalFrames,
  }) async {
    final files = <File>[];
    final durations = <double>[];
    
    debugPrint('[exportVideo] static slide: index=$slideIndex durationMs=${slideDuration.inMilliseconds} fps=$fps');
    
    // Go to the slide without animation
    _goToSlide(slideIndex, animate: false);
    final slide = _project.slides[slideIndex];
    await _ensureSlideImageReady(slide, slideIndex);
    await _waitForNextFrame();
    
    // OPTIMIZATION: For static slides, we only need ONE frame at the start
    // The entire slide duration is represented by this single frame in the concat demuxer
    final bytes = await _captureCurrentSlide();
    final frameFile = File(
      p.join(exportDir.path, 'frame_${startFrameIndex.toString().padLeft(4, '0')}.png'),
    );
    
    // Write file asynchronously in parallel (non-blocking)
    _writeFrameFile(frameFile, bytes);
    
    files.add(frameFile);
    // Duration is the full slide duration for this single frame
    durations.add(slideDuration.inMilliseconds / 1000.0);
    
    debugPrint('[exportVideo] static frame captured bytes=${bytes.length} duration=${slideDuration.inSeconds}s');
    
    // Update progress
    if (mounted) {
      _updateExportProgress(startFrameIndex + 1, totalFrames);
    }
    
    return _FrameCaptureResult(files: files, durations: durations);
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

  Future<String?> _materializeSelectedAudioFile() async {
    if (_selectedTrack == null) return null;
    try {
      final data = await rootBundle.load(_selectedTrack!.assetPath);
      final tempDir = await Directory.systemTemp.createTemp('slideshow_audio_');
      final audioPath = p.join(tempDir.path, p.basename(_selectedTrack!.assetPath));
      final file = File(audioPath);
      await file.writeAsBytes(data.buffer.asUint8List());
      return audioPath;
    } catch (e) {
      debugPrint('[exportVideo] failed to materialize audio: $e');
      return null;
    }
  }

  // Helper for parallel file writing - non-blocking
  void _writeFrameFile(File file, Uint8List bytes) {
    file.writeAsBytes(bytes).catchError((e) {
      debugPrint('[exportVideo] failed to write frame file: $e');
      return null;
    });
  }

  // Helper for updating progress dialog (avoids dialog recreation spam)
  void _updateExportProgress(int current, int total) {
    if (!mounted) return;
    Navigator.of(context).pop(); // Close current dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(
        message: 'Exporting slideshow',
        showProgress: true,
        current: current,
        total: total,
      ),
    );
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
