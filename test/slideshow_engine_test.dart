import 'package:flutter_test/flutter_test.dart';
import 'package:sz_pic_flutter/core/services/slideshow_engine.dart';
import 'package:sz_pic_flutter/core/models/image_item.dart';
import 'package:sz_pic_flutter/core/models/slideshow_models.dart';

ImageItem _image(String id) => ImageItem(
      id: id,
      path: '/tmp/$id.jpg',
      addedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('SlideshowEngine.createSlideshow', () {
    final engine = SlideshowEngine();

    test('creates one ordered slide per image with defaults', () {
      final project = engine.createSlideshow(images: [
        _image('a'),
        _image('b'),
        _image('c'),
      ]);

      expect(project.slides.length, 3);
      expect(project.slides.map((s) => s.order).toList(), [0, 1, 2]);
      expect(project.slides.map((s) => s.image.id).toList(), ['a', 'b', 'c']);

      for (final slide in project.slides) {
        expect(slide.duration, SlideshowEngine.defaultSlideDuration);
        expect(slide.transitionIn!.type, TransitionType.fade);
        expect(slide.transitionIn!.duration, SlideshowEngine.defaultTransitionDuration);
        expect(slide.transitionOut!.type, TransitionType.fade);
      }
    });

    test('total duration is the sum of slide durations', () {
      final project = engine.createSlideshow(
        images: [_image('a'), _image('b'), _image('c')],
        slideDuration: const Duration(seconds: 4),
      );
      expect(project.totalDuration, const Duration(seconds: 12));
    });

    test('custom transition type applies to in and out', () {
      final project = engine.createSlideshow(
        images: [_image('a')],
        transitionType: TransitionType.kenBurns,
      );
      expect(project.slides.first.transitionIn!.type, TransitionType.kenBurns);
      expect(project.slides.first.transitionOut!.type, TransitionType.kenBurns);
    });

    test('default name starts with "Slideshow"', () {
      final project = engine.createSlideshow(images: [_image('a')]);
      expect(project.name, startsWith('Slideshow'));
    });
  });

  group('SlideshowEngine mutations', () {
    final engine = SlideshowEngine();

    test('updateSlideDuration updates all slides and total', () {
      final project = engine.createSlideshow(images: [_image('a'), _image('b')]);
      final updated = engine.updateSlideDuration(
        project,
        const Duration(seconds: 10),
      );

      expect(updated.slides.every((s) => s.duration == const Duration(seconds: 10)), isTrue);
      expect(updated.totalDuration, const Duration(seconds: 20));
    });

    test('updateTransitionType updates every slide in and out', () {
      final project = engine.createSlideshow(images: [_image('a'), _image('b')]);
      final updated = engine.updateTransitionType(
        project,
        TransitionType.zoom,
        const Duration(milliseconds: 800),
      );

      for (final slide in updated.slides) {
        expect(slide.transitionIn!.type, TransitionType.zoom);
        expect(slide.transitionOut!.duration, const Duration(milliseconds: 800));
      }
    });

    test('reorderSlides resequences order values', () {
      final project = engine.createSlideshow(
        images: [_image('a'), _image('b'), _image('c')],
      );

      final reordered = engine.reorderSlides(project, 0, 2);

      expect(reordered.slides.map((s) => s.image.id).toList(), ['b', 'c', 'a']);
      expect(reordered.slides.map((s) => s.order).toList(), [0, 1, 2]);
    });

    test('removeSlide drops the slide, resequences, and recomputes duration', () {
      final project = engine.createSlideshow(
        images: [_image('a'), _image('b'), _image('c')],
      );

      final reduced = engine.removeSlide(project, project.slides[1].id);

      expect(reduced.slides.map((s) => s.image.id).toList(), ['a', 'c']);
      expect(reduced.slides.map((s) => s.order).toList(), [0, 1]);
      expect(
        reduced.totalDuration,
        SlideshowEngine.defaultSlideDuration * 2,
      );
    });

    test('addMusic then removeMusic actually clears the path', () {
      final project = engine.createSlideshow(images: [_image('a')]);

      final withMusic = engine.addMusic(project, 'assets/music/upbeat_carefree.mp3');
      expect(withMusic.musicPath, 'assets/music/upbeat_carefree.mp3');

      final withoutMusic = engine.removeMusic(withMusic);
      expect(withoutMusic.musicPath, isNull,
          reason: 'removeMusic must clear musicPath (regression: copyWith null bug)');
    });

    test('updateName changes the name', () {
      final project = engine.createSlideshow(images: [_image('a')]);
      expect(engine.updateName(project, 'Holiday').name, 'Holiday');
    });
  });

  group('SlideshowEngine.formatDuration', () {
    test('formats m:ss', () {
      expect(SlideshowEngine.formatDuration(const Duration(seconds: 0)), '0:00');
      expect(SlideshowEngine.formatDuration(const Duration(seconds: 5)), '0:05');
      expect(SlideshowEngine.formatDuration(const Duration(seconds: 60)), '1:00');
      expect(SlideshowEngine.formatDuration(const Duration(seconds: 150)), '2:30');
    });
  });

  group('SlideshowEngine.formatDurationLong', () {
    test('formats short durations as seconds only', () {
      expect(SlideshowEngine.formatDurationLong(const Duration(seconds: 45)), '45s');
      expect(SlideshowEngine.formatDurationLong(Duration.zero), '0s');
    });

    test('formats longer durations as minutes and seconds', () {
      expect(SlideshowEngine.formatDurationLong(const Duration(seconds: 90)), '1m 30s');
      expect(SlideshowEngine.formatDurationLong(const Duration(minutes: 2)), '2m 0s');
    });
  });
}
