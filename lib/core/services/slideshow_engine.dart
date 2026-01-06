import 'package:uuid/uuid.dart';
import '../models/image_item.dart';
import '../models/slideshow_models.dart';

/// Service for creating and managing slideshow projects
class SlideshowEngine {
  static const _uuid = Uuid();

  /// Default slide duration in seconds
  static const defaultSlideDuration = Duration(seconds: 3);

  /// Default transition duration
  static const defaultTransitionDuration = Duration(milliseconds: 500);

  /// Creates a new slideshow project from a list of images
  SlideshowProject createSlideshow({
    required List<ImageItem> images,
    String? name,
    Duration? slideDuration,
    TransitionType? transitionType,
  }) {
    final slideDurationValue = slideDuration ?? defaultSlideDuration;
    final transitionValue = transitionType ?? TransitionType.fade;

    final slides = images.asMap().entries.map((entry) {
      return Slide(
        id: _uuid.v4(),
        image: entry.value,
        duration: slideDurationValue,
        transitionIn: TransitionEffect(
          type: transitionValue,
          duration: defaultTransitionDuration,
        ),
        transitionOut: TransitionEffect(
          type: transitionValue,
          duration: defaultTransitionDuration,
        ),
        order: entry.key,
      );
    }).toList();

    final totalDuration = slides.fold<Duration>(
      Duration.zero,
      (sum, slide) => sum + slide.duration,
    );

    return SlideshowProject(
      id: _uuid.v4(),
      name: name ?? 'Slideshow ${DateTime.now().toIso8601String().split('T').first}',
      slides: slides,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalDuration: totalDuration,
    );
  }

  /// Updates the slide duration for all slides
  SlideshowProject updateSlideDuration(
    SlideshowProject project,
    Duration duration,
  ) {
    final updatedSlides = project.slides.map((slide) {
      return slide.copyWith(duration: duration);
    }).toList();

    final totalDuration = updatedSlides.fold<Duration>(
      Duration.zero,
      (sum, slide) => sum + slide.duration,
    );

    return project.copyWith(
      slides: updatedSlides,
      totalDuration: totalDuration,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates the transition type for all slides
  SlideshowProject updateTransitionType(
    SlideshowProject project,
    TransitionType type,
    Duration? duration,
  ) {
    final transitionDuration = duration ?? defaultTransitionDuration;
    final transitionEffect = TransitionEffect(
      type: type,
      duration: transitionDuration,
    );

    final updatedSlides = project.slides.map((slide) {
      return slide.copyWith(
        transitionIn: transitionEffect,
        transitionOut: transitionEffect,
      );
    }).toList();

    return project.copyWith(
      slides: updatedSlides,
      updatedAt: DateTime.now(),
    );
  }

  /// Reorders slides in the slideshow
  SlideshowProject reorderSlides(
    SlideshowProject project,
    int fromIndex,
    int toIndex,
  ) {
    final slides = List<Slide>.from(project.slides);
    final slide = slides.removeAt(fromIndex);
    slides.insert(toIndex, slide);

    // Update order values
    final updatedSlides = slides.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();

    return project.copyWith(
      slides: updatedSlides,
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a slide from the slideshow
  SlideshowProject removeSlide(SlideshowProject project, String slideId) {
    final updatedSlides = project.slides
        .where((slide) => slide.id != slideId)
        .toList();

    // Reorder remaining slides
    final reorderedSlides = updatedSlides.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();

    final totalDuration = reorderedSlides.fold<Duration>(
      Duration.zero,
      (sum, slide) => sum + slide.duration,
    );

    return project.copyWith(
      slides: reorderedSlides,
      totalDuration: totalDuration,
      updatedAt: DateTime.now(),
    );
  }

  /// Adds music to the slideshow
  SlideshowProject addMusic(SlideshowProject project, String musicPath) {
    return project.copyWith(
      musicPath: musicPath,
      updatedAt: DateTime.now(),
    );
  }

  /// Removes music from the slideshow
  SlideshowProject removeMusic(SlideshowProject project) {
    return project.copyWith(
      musicPath: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates the project name
  SlideshowProject updateName(SlideshowProject project, String name) {
    return project.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );
  }

  /// Gets a formatted duration string (e.g., "2:30")
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Gets a formatted time string for display (e.g., "1m 30s")
  static String formatDurationLong(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
