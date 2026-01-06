import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/image_item.dart';
import '../../core/models/slideshow_models.dart';
import '../../core/services/slideshow_engine.dart';

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
    final theme = Theme.of(context);

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
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveProject,
            tooltip: 'Save',
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
        return ClipRect(
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
      case TransitionType.dissolve:
      case TransitionType.fade:
      default:
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
      child: Image.file(
        File(slide.image.path),
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
                          child: const Text(
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

  void _saveProject() {
    // TODO: Implement save to SQLite
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project saved! (Demo)'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
