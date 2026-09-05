import 'package:flutter_test/flutter_test.dart';
import 'package:sz_pic_flutter/core/services/collage_engine.dart';
import 'package:sz_pic_flutter/core/models/collage_models.dart';

void main() {
  group('CollageEngine.createGridLayout', () {
    final engine = CollageEngine();

    test('4 images produce a 2x2 grid with uniform cells', () {
      const spacing = 0.02, padding = 0.04;
      final layout = engine.createGridLayout(
        imageCount: 4,
        spacing: spacing,
        padding: padding,
      );

      expect(layout.type, LayoutType.grid);
      expect(layout.cells.length, 4);

      final cellWidth = (1.0 - padding * 2 - spacing) / 2;
      final cellHeight = (1.0 - padding * 2 - spacing) / 2;

      for (final cell in layout.cells) {
        expect(cell.width, closeTo(cellWidth, 1e-9));
        expect(cell.height, closeTo(cellHeight, 1e-9));
      }

      // First cell top-left, second top-right
      expect(layout.cells[0].x, closeTo(padding, 1e-9));
      expect(layout.cells[0].y, closeTo(padding, 1e-9));
      expect(layout.cells[1].x, closeTo(padding + cellWidth + spacing, 1e-9));
      // Third row starts below the first
      expect(layout.cells[2].y, closeTo(padding + cellHeight + spacing, 1e-9));
    });

    test('5 images produce 3 columns (sqrt ceiling)', () {
      final layout = engine.createGridLayout(imageCount: 5);
      // 3 columns: cells 0,1,2 share the same y; cell 3 starts the next row
      expect(layout.cells.length, 5);
      expect(layout.cells[0].y, layout.cells[1].y);
      expect(layout.cells[1].y, layout.cells[2].y);
      expect(layout.cells[3].y, greaterThan(layout.cells[0].y));
    });

    test('all cells stay within normalized bounds', () {
      for (final count in [1, 2, 3, 6, 9, 12]) {
        final layout = engine.createGridLayout(imageCount: count);
        for (final cell in layout.cells) {
          expect(cell.x, greaterThanOrEqualTo(0.0));
          expect(cell.y, greaterThanOrEqualTo(0.0));
          expect(cell.x + cell.width, lessThanOrEqualTo(1.0 + 1e-9));
          expect(cell.y + cell.height, lessThanOrEqualTo(1.0 + 1e-9));
        }
      }
    });

    test('cell ids are unique', () {
      final layout = engine.createGridLayout(imageCount: 9);
      final ids = layout.cells.map((c) => c.id).toSet();
      expect(ids.length, layout.cells.length);
    });
  });

  group('CollageEngine.createMasonryLayout', () {
    final engine = CollageEngine();

    test('cells snap to column x positions', () {
      const columns = 2, spacing = 0.02, padding = 0.04;
      final layout = engine.createMasonryLayout(
        imageCount: 6,
        columns: columns,
        spacing: spacing,
        padding: padding,
      );

      expect(layout.type, LayoutType.masonry);
      expect(layout.cells.length, 6);

      final colWidth = (1.0 - padding * 2 - spacing) / columns;
      final col0X = padding;
      final col1X = padding + colWidth + spacing;

      for (final cell in layout.cells) {
        expect(
          cell.x,
          anyOf(closeTo(col0X, 1e-9), closeTo(col1X, 1e-9)),
          reason: 'cell x must align with a column',
        );
        expect(cell.width, closeTo(colWidth, 1e-9));
      }
    });

    test('first two cells land in different columns', () {
      final layout = engine.createMasonryLayout(imageCount: 4, columns: 2);
      expect(layout.cells[0].x, isNot(closeTo(layout.cells[1].x, 1e-9)));
    });

    test('heights vary for visual interest', () {
      final layout = engine.createMasonryLayout(imageCount: 10, columns: 3);
      final heights = layout.cells.map((c) => c.height).toSet();
      expect(heights.length, greaterThan(1), reason: 'random heights should differ');
    });
  });

  group('CollageEngine.createTemplateLayout', () {
    final engine = CollageEngine();

    test('templates exist for 2-5 images', () {
      for (final count in [2, 3, 4, 5]) {
        final layout = engine.createTemplateLayout(imageCount: count);
        expect(layout.type, LayoutType.template, reason: '$count-image template');
        expect(layout.cells.length, count);
      }
    });

    test('2-image template is side-by-side full height', () {
      const padding = 0.04, spacing = 0.02;
      final layout = engine.createTemplateLayout(
        imageCount: 2,
        spacing: spacing,
        padding: padding,
      );

      expect(layout.cells[0].y, closeTo(padding, 1e-9));
      expect(layout.cells[0].height, closeTo(1.0 - padding * 2, 1e-9));
      expect(layout.cells[1].height, closeTo(layout.cells[0].height, 1e-9));
      expect(
        layout.cells[1].x,
        closeTo(layout.cells[0].x + layout.cells[0].width + spacing, 1e-9),
      );
    });

    test('6+ images fall back to grid', () {
      final layout = engine.createTemplateLayout(imageCount: 6);
      expect(layout.type, LayoutType.grid);
      expect(layout.cells.length, 6);
    });
  });

  group('CollageEngine.createFreestyleLayout', () {
    final engine = CollageEngine();

    test('cells stay inside padded bounds with rotation limits', () {
      for (final count in [1, 2, 3, 4, 6]) {
        final layout = engine.createFreestyleLayout(imageCount: count);
        expect(layout.type, LayoutType.freestyle);
        expect(layout.cells.length, count);

        for (final cell in layout.cells) {
          expect(cell.x, greaterThanOrEqualTo(0.0));
          expect(cell.y, greaterThanOrEqualTo(0.0));
          expect(cell.x + cell.width, lessThanOrEqualTo(1.0 + 1e-9));
          expect(cell.y + cell.height, lessThanOrEqualTo(1.0 + 1e-9));
          expect(cell.rotation, inInclusiveRange(-15.0, 15.0));
        }
      }
    });
  });

  group('CollageEngine.updateCell', () {
    final engine = CollageEngine();

    test('replaces only the target cell', () {
      final layout = engine.createGridLayout(imageCount: 4);
      final target = layout.cells[2];
      final moved = target.copyWith(x: 0.5, y: 0.5, rotation: 45);

      final updated = engine.updateCell(layout, target.id, moved);

      expect(updated.cells[2], moved);
      expect(updated.cells[0], layout.cells[0]);
      expect(updated.cells[1], layout.cells[1]);
      expect(updated.cells[3], layout.cells[3]);
      expect(layout.cells[2].x, isNot(0.5), reason: 'original layout is unchanged');
    });
  });

  group('CollageEngine.assignImagesToLayout', () {
    final engine = CollageEngine();

    test('assigns images in order', () {
      final layout = engine.createGridLayout(imageCount: 3);
      final assigned = engine.assignImagesToLayout(layout, ['a', 'b', 'c']);

      expect(assigned.cells[0].imageId, 'a');
      expect(assigned.cells[1].imageId, 'b');
      expect(assigned.cells[2].imageId, 'c');
    });

    test('fewer images than cells clears the leftover cells', () {
      final layout = engine.createGridLayout(imageCount: 4)
          .let((l) => engine.assignImagesToLayout(l, ['a', 'b', 'c', 'd']));

      // Re-assign with fewer images: extras must be cleared, not stale
      final reassigned = engine.assignImagesToLayout(layout, ['x', 'y']);

      expect(reassigned.cells[0].imageId, 'x');
      expect(reassigned.cells[1].imageId, 'y');
      expect(reassigned.cells[2].imageId, isNull,
          reason: 'cells beyond the image list must be cleared');
      expect(reassigned.cells[3].imageId, isNull);
    });
  });
}

extension<T> on T {
  T let(T Function(T) f) => f(this);
}
