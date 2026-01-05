import 'package:equatable/equatable.dart';
import 'image_item.dart';

/// Layout type for collage
enum LayoutType {
  grid,
  masonry,
  template,
  freestyle,
  smart, // AI-powered layout
}

/// Represents a cell in the collage layout
class LayoutCell extends Equatable {
  final String id;
  final double x; // Normalized position (0-1)
  final double y; // Normalized position (0-1)
  final double width; // Normalized size (0-1)
  final double height; // Normalized size (0-1)
  final String? imageId;
  final double rotation; // In degrees
  final double scale;
  final double imageOffsetX; // For free crop: normalized offset within cell (-0.5 to 0.5)
  final double imageOffsetY; // For free crop: normalized offset within cell (-0.5 to 0.5)

  const LayoutCell({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.imageId,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
  });

  LayoutCell copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    String? imageId,
    double? rotation,
    double? scale,
    double? imageOffsetX,
    double? imageOffsetY,
  }) {
    return LayoutCell(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      imageId: imageId ?? this.imageId,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      imageOffsetX: imageOffsetX ?? this.imageOffsetX,
      imageOffsetY: imageOffsetY ?? this.imageOffsetY,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'imageId': imageId,
      'rotation': rotation,
      'scale': scale,
      'imageOffsetX': imageOffsetX,
      'imageOffsetY': imageOffsetY,
    };
  }

  factory LayoutCell.fromJson(Map<String, dynamic> json) {
    return LayoutCell(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      imageId: json['imageId'] as String?,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      imageOffsetX: (json['imageOffsetX'] as num?)?.toDouble() ?? 0.0,
      imageOffsetY: (json['imageOffsetY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, x, y, width, height, imageId, rotation, scale, imageOffsetX, imageOffsetY];
}

/// Represents a complete collage layout
class CollageLayout extends Equatable {
  final String id;
  final LayoutType type;
  final List<LayoutCell> cells;
  final double aspectRatio; // width/height
  final int backgroundColor;
  final double spacing;
  final double padding;

  const CollageLayout({
    required this.id,
    required this.type,
    required this.cells,
    this.aspectRatio = 1.0,
    this.backgroundColor = 0xFFFFFFFF,
    this.spacing = 0.01,
    this.padding = 0.02,
  });

  CollageLayout copyWith({
    String? id,
    LayoutType? type,
    List<LayoutCell>? cells,
    double? aspectRatio,
    int? backgroundColor,
    double? spacing,
    double? padding,
  }) {
    return CollageLayout(
      id: id ?? this.id,
      type: type ?? this.type,
      cells: cells ?? this.cells,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      spacing: spacing ?? this.spacing,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'cells': cells.map((cell) => cell.toJson()).toList(),
      'aspectRatio': aspectRatio,
      'backgroundColor': backgroundColor,
      'spacing': spacing,
      'padding': padding,
    };
  }

  factory CollageLayout.fromJson(Map<String, dynamic> json) {
    return CollageLayout(
      id: json['id'] as String,
      type: LayoutType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LayoutType.grid,
      ),
      cells: (json['cells'] as List)
          .map((cell) => LayoutCell.fromJson(cell as Map<String, dynamic>))
          .toList(),
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? 1.0,
      backgroundColor: json['backgroundColor'] as int? ?? 0xFFFFFFFF,
      spacing: (json['spacing'] as num?)?.toDouble() ?? 0.01,
      padding: (json['padding'] as num?)?.toDouble() ?? 0.02,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, cells, aspectRatio, backgroundColor, spacing, padding];
}

/// Represents a collage project
class CollageProject extends Equatable {
  final String id;
  final String name;
  final CollageLayout layout;
  final List<ImageItem> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;

  const CollageProject({
    required this.id,
    required this.name,
    required this.layout,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
  });

  CollageProject copyWith({
    String? id,
    String? name,
    CollageLayout? layout,
    List<ImageItem>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
  }) {
    return CollageProject(
      id: id ?? this.id,
      name: name ?? this.name,
      layout: layout ?? this.layout,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'layout': layout.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'thumbnailPath': thumbnailPath,
    };
  }

  factory CollageProject.fromJson(Map<String, dynamic> json) {
    return CollageProject(
      id: json['id'] as String,
      name: json['name'] as String,
      layout: CollageLayout.fromJson(json['layout'] as Map<String, dynamic>),
      images: (json['images'] as List)
          .map((img) => ImageItem.fromJson(img as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, layout, images, createdAt, updatedAt, thumbnailPath];
}
