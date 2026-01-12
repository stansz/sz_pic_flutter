import 'package:equatable/equatable.dart';

class MusicTrack extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String assetPath;
  final String licenseName;
  final String licenseUrl;
  final String attributionText;
  final String sourceUrl;
  final Duration? duration; // Optional, can be filled after probing

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.assetPath,
    required this.licenseName,
    required this.licenseUrl,
    required this.attributionText,
    required this.sourceUrl,
    this.duration,
  });

  MusicTrack copyWith({Duration? duration}) {
    return MusicTrack(
      id: id,
      title: title,
      artist: artist,
      genre: genre,
      assetPath: assetPath,
      licenseName: licenseName,
      licenseUrl: licenseUrl,
      attributionText: attributionText,
      sourceUrl: sourceUrl,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        genre,
        assetPath,
        licenseName,
        licenseUrl,
        attributionText,
        sourceUrl,
        duration,
      ];
}
