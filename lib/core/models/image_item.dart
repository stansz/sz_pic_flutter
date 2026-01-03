import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Represents an image in the app with metadata
class ImageItem extends Equatable {
  final String id;
  final String path;
  final String? name;
  final DateTime addedAt;
  final int? width;
  final int? height;
  final int? fileSize;
  final Uint8List? bytes;

  const ImageItem({
    required this.id,
    required this.path,
    this.name,
    required this.addedAt,
    this.width,
    this.height,
    this.fileSize,
    this.bytes,
  });

  ImageItem copyWith({
    String? id,
    String? path,
    String? name,
    DateTime? addedAt,
    int? width,
    int? height,
    int? fileSize,
    Uint8List? bytes,
  }) {
    return ImageItem(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      addedAt: addedAt ?? this.addedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      bytes: bytes ?? this.bytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'addedAt': addedAt.toIso8601String(),
      'width': width,
      'height': height,
      'fileSize': fileSize,
    };
  }

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      id: json['id'] as String,
      path: json['path'] as String,
      name: json['name'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      width: json['width'] as int?,
      height: json['height'] as int?,
      fileSize: json['fileSize'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, path, name, addedAt, width, height, fileSize];
}
