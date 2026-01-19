// Copyright (c) 2026
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
