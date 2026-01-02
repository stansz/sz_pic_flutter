import 'package:equatable/equatable.dart';
import 'image_item.dart';

/// Type of transition effect between slides
enum TransitionType {
  fade,
  slide,
  zoom,
  dissolve,
  kenBurns, // Pan and zoom effect
}

/// Represents a transition effect configuration
class TransitionEffect extends Equatable {
  final TransitionType type;
  final Duration duration;
  final Map<String, dynamic>? parameters;

  const TransitionEffect({
    required this.type,
    this.duration = const Duration(milliseconds: 500),
    this.parameters,
  });

  TransitionEffect copyWith({
    TransitionType? type,
    Duration? duration,
    Map<String, dynamic>? parameters,
  }) {
    return TransitionEffect(
      type: type ?? this.type,
      duration: duration ?? this.duration,
      parameters: parameters ?? this.parameters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'duration': duration.inMilliseconds,
      'parameters': parameters,
    };
  }

  factory TransitionEffect.fromJson(Map<String, dynamic> json) {
    return TransitionEffect(
      type: TransitionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransitionType.fade,
      ),
      duration: Duration(milliseconds: json['duration'] as int),
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [type, duration, parameters];
}

/// Represents a single slide in a slideshow
class Slide extends Equatable {
  final String id;
  final ImageItem image;
  final Duration duration;
  final TransitionEffect? transitionIn;
  final TransitionEffect? transitionOut;
  final int order;

  const Slide({
    required this.id,
    required this.image,
    this.duration = const Duration(seconds: 3),
    this.transitionIn,
    this.transitionOut,
    required this.order,
  });

  Slide copyWith({
    String? id,
    ImageItem? image,
    Duration? duration,
    TransitionEffect? transitionIn,
    TransitionEffect? transitionOut,
    int? order,
  }) {
    return Slide(
      id: id ?? this.id,
      image: image ?? this.image,
      duration: duration ?? this.duration,
      transitionIn: transitionIn ?? this.transitionIn,
      transitionOut: transitionOut ?? this.transitionOut,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image.toJson(),
      'duration': duration.inMilliseconds,
      'transitionIn': transitionIn?.toJson(),
      'transitionOut': transitionOut?.toJson(),
      'order': order,
    };
  }

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] as String,
      image: ImageItem.fromJson(json['image'] as Map<String, dynamic>),
      duration: Duration(milliseconds: json['duration'] as int),
      transitionIn: json['transitionIn'] != null
          ? TransitionEffect.fromJson(json['transitionIn'] as Map<String, dynamic>)
          : null,
      transitionOut: json['transitionOut'] != null
          ? TransitionEffect.fromJson(json['transitionOut'] as Map<String, dynamic>)
          : null,
      order: json['order'] as int,
    );
  }

  @override
  List<Object?> get props => [id, image, duration, transitionIn, transitionOut, order];
}

/// Represents a slideshow project
class SlideshowProject extends Equatable {
  final String id;
  final String name;
  final List<Slide> slides;
  final String? musicPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final Duration totalDuration;

  const SlideshowProject({
    required this.id,
    required this.name,
    required this.slides,
    this.musicPath,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    required this.totalDuration,
  });

  SlideshowProject copyWith({
    String? id,
    String? name,
    List<Slide>? slides,
    String? musicPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
    Duration? totalDuration,
  }) {
    return SlideshowProject(
      id: id ?? this.id,
      name: name ?? this.name,
      slides: slides ?? this.slides,
      musicPath: musicPath ?? this.musicPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slides': slides.map((slide) => slide.toJson()).toList(),
      'musicPath': musicPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'thumbnailPath': thumbnailPath,
      'totalDuration': totalDuration.inMilliseconds,
    };
  }

  factory SlideshowProject.fromJson(Map<String, dynamic> json) {
    return SlideshowProject(
      id: json['id'] as String,
      name: json['name'] as String,
      slides: (json['slides'] as List)
          .map((slide) => Slide.fromJson(slide as Map<String, dynamic>))
          .toList(),
      musicPath: json['musicPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      thumbnailPath: json['thumbnailPath'] as String?,
      totalDuration: Duration(milliseconds: json['totalDuration'] as int),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, slides, musicPath, createdAt, updatedAt, thumbnailPath, totalDuration];
}
