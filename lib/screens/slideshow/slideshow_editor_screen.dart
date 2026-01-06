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

class _SlideshowEditorScreenState extends State<SlideshowEditorScreen> {
  late SlideshowProject _project;
  int _currentSlideIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _remainingTime = _project.slides.isNotEmpty
        ? _project.slides[0].duration
        : Duration.zero;
  }

  @override
  void dispose() {
    _stopPlayback();
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

    final currentSlide = _project.slides[_currentSlideIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Current Image
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    final transitionType = currentSlide.transitionIn?.type;
                    switch (transitionType) {
                      case TransitionType.slide:
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      case TransitionType.zoom:
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                          child: child,
                        );
                      case TransitionType.dissolve:
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      case TransitionType.fade:
                      case TransitionType.kenBurns:
                      default:
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                    }
                  },
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.file(
                      File(currentSlide.image.path),
                      key: ValueKey(currentSlide.id),
                    ),
                  ),
                ),
              ),

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

        setState(() {
          if (_remainingTime.inMilliseconds > 100) {
            _remainingTime = _remainingTime - const Duration(milliseconds: 100);
          } else {
            // Move to next slide
            if (_currentSlideIndex < _project.slides.length - 1) {
              _currentSlideIndex++;
              _remainingTime = _project.slides[_currentSlideIndex].duration;
            } else {
              // End of slideshow
              _stopPlayback();
              _currentSlideIndex = 0;
              _remainingTime = _project.slides[0].duration;
            }
          }
        });
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
    setState(() {
      if (_currentSlideIndex > 0) {
        _currentSlideIndex--;
        _remainingTime = _project.slides[_currentSlideIndex].duration;
      }
    });
  }

  void _nextSlide() {
    _stopPlayback();
    setState(() {
      if (_currentSlideIndex < _project.slides.length - 1) {
        _currentSlideIndex++;
        _remainingTime = _project.slides[_currentSlideIndex].duration;
      }
    });
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
      _currentSlideIndex = 0;
      _remainingTime = _project.slides.isNotEmpty
          ? _project.slides[0].duration
          : Duration.zero;
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
                          value: _project.slides.isNotEmpty
                              ? _project.slides[0].transitionIn?.type
                              : TransitionType.fade,
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
                              });
                              // Also update the modal state to rebuild the bottom sheet
                              setModalState(() {});
                            }
                          },
                          items: TransitionType.values.map((type) {
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
