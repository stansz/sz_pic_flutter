import 'package:equatable/equatable.dart';

/// Enum representing the type of project
enum ProjectType {
  collage,
  slideshow,
  photo,
}

/// Extension for ProjectType to provide string conversion
extension ProjectTypeExtension on ProjectType {
  String toValue() {
    switch (this) {
      case ProjectType.collage:
        return 'collage';
      case ProjectType.slideshow:
        return 'slideshow';
      case ProjectType.photo:
        return 'photo';
    }
  }

  static ProjectType fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'collage':
        return ProjectType.collage;
      case 'slideshow':
        return ProjectType.slideshow;
      case 'photo':
        return ProjectType.photo;
      default:
        throw ArgumentError('Invalid ProjectType value: $value');
    }
  }
}

/// Data model for photo editor state
class PhotoEditData extends Equatable {
  final String imageId;
  final String imagePath;
  final Map<String, dynamic> filter;
  final Map<String, dynamic>? comparisonSettings;

  const PhotoEditData({
    required this.imageId,
    required this.imagePath,
    required this.filter,
    this.comparisonSettings,
  });

  PhotoEditData copyWith({
    String? imageId,
    String? imagePath,
    Map<String, dynamic>? filter,
    Map<String, dynamic>? comparisonSettings,
  }) {
    return PhotoEditData(
      imageId: imageId ?? this.imageId,
      imagePath: imagePath ?? this.imagePath,
      filter: filter ?? this.filter,
      comparisonSettings: comparisonSettings ?? this.comparisonSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'imagePath': imagePath,
      'filter': filter,
      'comparisonSettings': comparisonSettings,
    };
  }

  factory PhotoEditData.fromJson(Map<String, dynamic> json) {
    return PhotoEditData(
      imageId: json['imageId'] as String,
      imagePath: json['imagePath'] as String,
      filter: json['filter'] as Map<String, dynamic>,
      comparisonSettings: json['comparisonSettings'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [imageId, imagePath, filter, comparisonSettings];
}

/// Unified project model for all project types
class Project extends Equatable {
  final String id;
  final String name;
  final ProjectType type;
  final Map<String, dynamic> data; // Stores CollageProject, SlideshowProject, or PhotoEditData
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final bool isDraft; // true = auto-saved draft, false = manually saved
  final int? autoSaveVersion; // Incremented on each auto-save

  const Project({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.isDraft = true,
    this.autoSaveVersion,
  });

  Project copyWith({
    String? id,
    String? name,
    ProjectType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
    bool? isDraft,
    int? autoSaveVersion,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isDraft: isDraft ?? this.isDraft,
      autoSaveVersion: autoSaveVersion ?? this.autoSaveVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toValue(),
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'thumbnailPath': thumbnailPath,
      'isDraft': isDraft ? 1 : 0,
      'autoSaveVersion': autoSaveVersion,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ProjectTypeExtension.fromValue(json['type'] as String),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      thumbnailPath: json['thumbnailPath'] as String?,
      isDraft: (json['isDraft'] as int?) == 1,
      autoSaveVersion: json['autoSaveVersion'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        data,
        createdAt,
        updatedAt,
        thumbnailPath,
        isDraft,
        autoSaveVersion,
      ];
}
