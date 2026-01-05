import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/collage_models.dart';

/// Service for creating and manipulating collage layouts
class CollageEngine {
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  /// Create a grid layout
  CollageLayout createGridLayout({
    required int imageCount,
    double aspectRatio = 1.0,
    double spacing = 0.01,
    double padding = 0.02,
  }) {
    // Calculate optimal grid dimensions
    final cols = sqrt(imageCount).ceil();
    final rows = (imageCount / cols).ceil();

    final cellWidth = (1.0 - (padding * 2) - (spacing * (cols - 1))) / cols;
    final cellHeight = (1.0 - (padding * 2) - (spacing * (rows - 1))) / rows;

    final cells = <LayoutCell>[];
    for (var i = 0; i < imageCount; i++) {
      final row = i ~/ cols;
      final col = i % cols;

      cells.add(LayoutCell(
        id: _uuid.v4(),
        x: padding + (col * (cellWidth + spacing)),
        y: padding + (row * (cellHeight + spacing)),
        width: cellWidth,
        height: cellHeight,
      ));
    }

    return CollageLayout(
      id: _uuid.v4(),
      type: LayoutType.grid,
      cells: cells,
      aspectRatio: aspectRatio,
      spacing: spacing,
      padding: padding,
    );
  }

  /// Create a masonry layout (Pinterest-style)
  CollageLayout createMasonryLayout({
    required int imageCount,
    int columns = 2,
    double aspectRatio = 0.75,
    double spacing = 0.01,
    double padding = 0.02,
  }) {
    final cellWidth = (1.0 - (padding * 2) - (spacing * (columns - 1))) / columns;
    final cells = <LayoutCell>[];
    final columnHeights = List<double>.filled(columns, padding);

    for (var i = 0; i < imageCount; i++) {
      // Find shortest column
      var shortestCol = 0;
      var shortestHeight = columnHeights[0];
      for (var j = 1; j < columns; j++) {
        if (columnHeights[j] < shortestHeight) {
          shortestHeight = columnHeights[j];
          shortestCol = j;
        }
      }

      // Random height for variety
      final cellHeight = cellWidth * (0.8 + _random.nextDouble() * 0.6);

      cells.add(LayoutCell(
        id: _uuid.v4(),
        x: padding + (shortestCol * (cellWidth + spacing)),
        y: columnHeights[shortestCol],
        width: cellWidth,
        height: cellHeight,
      ));

      columnHeights[shortestCol] += cellHeight + spacing;
    }

    return CollageLayout(
      id: _uuid.v4(),
      type: LayoutType.masonry,
      cells: cells,
      aspectRatio: aspectRatio,
      spacing: spacing,
      padding: padding,
    );
  }

  /// Create a template-based layout (predefined attractive layouts)
  CollageLayout createTemplateLayout({
    required int imageCount,
    String? templateName,
    double aspectRatio = 1.0,
    double spacing = 0.01,
    double padding = 0.02,
  }) {
    switch (imageCount) {
      case 2:
        return _create2ImageTemplate(aspectRatio, spacing, padding);
      case 3:
        return _create3ImageTemplate(aspectRatio, spacing, padding);
      case 4:
        return _create4ImageTemplate(aspectRatio, spacing, padding);
      case 5:
        return _create5ImageTemplate(aspectRatio, spacing, padding);
      default:
        return createGridLayout(
          imageCount: imageCount,
          aspectRatio: aspectRatio,
          spacing: spacing,
          padding: padding,
        );
    }
  }

  CollageLayout _create2ImageTemplate(double aspectRatio, double spacing, double padding) {
    final cellWidth = (1.0 - (padding * 2) - spacing) / 2;
    final cellHeight = 1.0 - (padding * 2);

    return CollageLayout(
      id: _uuid.v4(),
      type: LayoutType.template,
      cells: [
        LayoutCell(
          id: _uuid.v4(),
          x: padding,
          y: padding,
          width: cellWidth,
          height: cellHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding + cellWidth + spacing,
          y: padding,
          width: cellWidth,
          height: cellHeight,
        ),
      ],
      aspectRatio: aspectRatio,
      spacing: spacing,
      padding: padding,
    );
  }

  CollageLayout _create3ImageTemplate(double aspectRatio, double spacing, double padding) {
    final leftWidth = 0.6 - padding;
    final rightWidth = 0.4 - padding - spacing;
    final topHeight = (1.0 - (padding * 2) - spacing) / 2;

    return CollageLayout(
      id: _uuid.v4(),
      type: LayoutType.template,
      cells: [
        LayoutCell(
          id: _uuid.v4(),
          x: padding,
          y: padding,
          width: leftWidth,
          height: 1.0 - (padding * 2),
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding + leftWidth + spacing,
          y: padding,
          width: rightWidth,
          height: topHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding + leftWidth + spacing,
          y: padding + topHeight + spacing,
          width: rightWidth,
          height: topHeight,
        ),
      ],
      aspectRatio: aspectRatio,
      spacing: spacing,
      padding: padding,
    );
  }

  CollageLayout _create4ImageTemplate(double aspectRatio, double spacing, double padding) {
    final cellWidth = (1.0 - (padding * 2) - spacing) / 2;
    final cellHeight = (1.0 - (padding * 2) - spacing) / 2;

    return CollageLayout(
      id: _uuid.v4(),
      type: LayoutType.template,
      cells: [
        LayoutCell(
          id: _uuid.v4(),
          x: padding,
          y: padding,
          width: cellWidth,
          height: cellHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding + cellWidth + spacing,
          y: padding,
          width: cellWidth,
          height: cellHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding,
          y: padding + cellHeight + spacing,
          width: cellWidth,
          height: cellHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding + cellWidth + spacing,
          y: padding + cellHeight + spacing,
          width: cellWidth,
          height: cellHeight,
        ),
      ],
      aspectRatio: aspectRatio,
      spacing: spacing,
      padding: padding,
    );
  }

  CollageLayout _create5ImageTemplate(double aspectRatio, double spacing, double padding) {
    final topWidth = (1.0 - (padding * 2) - spacing) / 2;
    final topHeight = 0.6 - padding;
    final bottomWidth = (1.0 - (padding * 2) - (spacing * 2)) / 3;
    final bottomHeight = 0.4 - padding - spacing;

    return CollageLayout(
      id: _uuid.v4(),
      type: LayoutType.template,
      cells: [
        LayoutCell(
          id: _uuid.v4(),
          x: padding,
          y: padding,
          width: topWidth,
          height: topHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding + topWidth + spacing,
          y: padding,
          width: topWidth,
          height: topHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding,
          y: padding + topHeight + spacing,
          width: bottomWidth,
          height: bottomHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding + bottomWidth + spacing,
          y: padding + topHeight + spacing,
          width: bottomWidth,
          height: bottomHeight,
        ),
        LayoutCell(
          id: _uuid.v4(),
          x: padding + (bottomWidth + spacing) * 2,
          y: padding + topHeight + spacing,
          width: bottomWidth,
          height: bottomHeight,
        ),
      ],
      aspectRatio: aspectRatio,
      spacing: spacing,
      padding: padding,
    );
  }

  /// Create a freestyle layout with random positions
  CollageLayout createFreestyleLayout({
    required int imageCount,
    double aspectRatio = 1.0,
    double spacing = 0.01,
    double padding = 0.05,
  }) {
    final cells = <LayoutCell>[];

    double cellMinSize = 0.2;
    double cellMaxSize = 0.4;

    if (imageCount == 1) {
      cellMinSize = cellMaxSize = 1.0 - padding * 2;
    } else if (imageCount == 2) {
      cellMinSize = 0.5;
      cellMaxSize = 0.8;
    } else if (imageCount == 3) {
      cellMinSize = 0.35;
      cellMaxSize = 0.65;
    } else if (imageCount == 4) {
      cellMinSize = 0.3;
      cellMaxSize = 0.55;
    }

    cellMinSize = cellMinSize.clamp(0.1, 1.0 - padding * 2);
    cellMaxSize = cellMaxSize.clamp(cellMinSize, 1.0 - padding * 2);

    for (var i = 0; i < imageCount; i++) {
      final width = cellMinSize + _random.nextDouble() * (cellMaxSize - cellMinSize);
      final height = cellMinSize + _random.nextDouble() * (cellMaxSize - cellMinSize);

      final availableWidth = max(0.0, 1.0 - padding * 2 - width);
      final availableHeight = max(0.0, 1.0 - padding * 2 - height);
      final x = padding + _random.nextDouble() * availableWidth;
      final y = padding + _random.nextDouble() * availableHeight;

      final rotation = -15 + _random.nextDouble() * 30;

      cells.add(LayoutCell(
        id: _uuid.v4(),
        x: x,
        y: y,
        width: width,
        height: height,
        rotation: rotation,
      ));
    }

    return CollageLayout(
      id: _uuid.v4(),
      type: LayoutType.freestyle,
      cells: cells,
      aspectRatio: aspectRatio,
      spacing: spacing,
      padding: padding,
    );
  }

  /// Update a specific cell in the layout
  CollageLayout updateCell(CollageLayout layout, String cellId, LayoutCell newCell) {
    final updatedCells = layout.cells.map((cell) {
      return cell.id == cellId ? newCell : cell;
    }).toList();

    return layout.copyWith(cells: updatedCells);
  }

  /// Assign images to cells
  CollageLayout assignImagesToLayout(
    CollageLayout layout,
    List<String> imageIds,
  ) {
    final updatedCells = <LayoutCell>[];
    
    for (var i = 0; i < layout.cells.length; i++) {
      final cell = layout.cells[i];
      final imageId = i < imageIds.length ? imageIds[i] : null;
      updatedCells.add(cell.copyWith(imageId: imageId));
    }

    return layout.copyWith(cells: updatedCells);
  }
}
