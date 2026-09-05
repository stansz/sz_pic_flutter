import 'package:flutter_test/flutter_test.dart';
import 'package:sz_pic_flutter/core/models/collage_models.dart';
import 'package:sz_pic_flutter/core/models/image_item.dart';
import 'package:sz_pic_flutter/core/models/slideshow_models.dart';

void main() {
  group('LayoutCell', () {
    const cell = LayoutCell(
      id: 'cell-1',
      x: 0.1,
      y: 0.2,
      width: 0.3,
      height: 0.4,
      imageId: 'img-1',
    );

    test('copyWith changes only the given fields', () {
      final moved = cell.copyWith(x: 0.9, rotation: 15);
      expect(moved.x, 0.9);
      expect(moved.rotation, 15);
      expect(moved.y, cell.y);
      expect(moved.width, cell.width);
      expect(moved.imageId, cell.imageId);
    });

    test('copyWith(imageId: null) clears the imageId (sentinel)', () {
      final cleared = cell.copyWith(imageId: null);
      expect(cleared.imageId, isNull,
          reason: 'explicit null must clear, not keep the old value');
    });

    test('JSON roundtrip preserves all fields', () {
      final restored = LayoutCell.fromJson(cell.toJson());
      expect(restored, cell);
    });

    test('fromJson applies defaults for missing optional fields', () {
      final restored = LayoutCell.fromJson({
        'id': 'c2',
        'x': 0.0,
        'y': 0.0,
        'width': 0.5,
        'height': 0.5,
      });
      expect(restored.rotation, 0.0);
      expect(restored.scale, 1.0);
      expect(restored.imageOffsetX, 0.0);
      expect(restored.imageOffsetY, 0.0);
      expect(restored.imageId, isNull);
    });
  });

  group('CollageLayout', () {
    final layout = CollageLayout(
      id: 'layout-1',
      type: LayoutType.masonry,
      cells: const [
        LayoutCell(id: 'c1', x: 0, y: 0, width: 0.5, height: 0.4, imageId: 'i1'),
        LayoutCell(id: 'c2', x: 0.5, y: 0, width: 0.5, height: 0.6, rotation: 12.5),
      ],
      aspectRatio: 0.75,
      backgroundColor: 0xFF123456,
      spacing: 0.03,
      padding: 0.05,
    );

    test('defaults', () {
      const fresh = CollageLayout(id: 'x', type: LayoutType.grid, cells: []);
      expect(fresh.aspectRatio, 1.0);
      expect(fresh.backgroundColor, 0xFFFFFFFF);
      expect(fresh.spacing, 0.01);
      expect(fresh.padding, 0.02);
    });

    test('JSON roundtrip preserves layout and cells', () {
      final restored = CollageLayout.fromJson(layout.toJson());
      expect(restored, layout);
      expect(restored.cells.length, 2);
      expect(restored.cells[1].rotation, 12.5);
    });

    test('copyWith replaces cells list', () {
      final updated = layout.copyWith(spacing: 0.1);
      expect(updated.spacing, 0.1);
      expect(updated.cells, layout.cells);
      expect(updated.type, LayoutType.masonry);
    });
  });

  group('TransitionEffect', () {
    test('JSON roundtrip', () {
      const effect = TransitionEffect(
        type: TransitionType.kenBurns,
        duration: Duration(milliseconds: 900),
      );
      expect(TransitionEffect.fromJson(effect.toJson()), effect);
    });

    test('unknown transition type falls back to fade', () {
      final restored = TransitionEffect.fromJson({
        'type': 'doesNotExist',
        'duration': 500,
      });
      expect(restored.type, TransitionType.fade,
          reason: 'legacy/unknown projects must not crash loading');
    });
  });

  group('ImageItem', () {
    test('copyWith and equality', () {
      final a = ImageItem(
        id: 'img-1',
        path: '/tmp/a.jpg',
        addedAt: DateTime(2026, 1, 1),
        width: 100,
        height: 50,
      );
      final renamed = a.copyWith(name: 'photo.jpg');
      expect(renamed.name, 'photo.jpg');
      expect(renamed.id, a.id);
      expect(renamed.path, a.path);
      expect(renamed == a, isFalse);
      // No-arg copyWith yields an equal instance (Equatable contract)
      expect(a.copyWith(), a);
    });
  });
}
