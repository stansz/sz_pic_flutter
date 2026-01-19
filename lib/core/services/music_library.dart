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

import '../models/music_track.dart';

/// Static catalog of bundled music tracks.
/// NOTE: Ensure the actual MP3 files are placed in assets/music/ with matching filenames.
class MusicLibrary {
  static final List<MusicTrack> tracks = [
    MusicTrack(
      id: 'upbeat_carefree',
      title: 'Carefree',
      artist: 'Kevin MacLeod',
      genre: 'Upbeat',
      assetPath: 'assets/music/upbeat_carefree.mp3',
      licenseName: 'CC BY 3.0',
      licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
      attributionText: '"Carefree" by Kevin MacLeod (CC BY 3.0) – https://incompetech.com',
      sourceUrl: 'https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1400037',
    ),
    MusicTrack(
      id: 'nostalgic_dream_culture',
      title: 'Dream Culture',
      artist: 'Kevin MacLeod',
      genre: 'Nostalgic',
      assetPath: 'assets/music/nostalgic_dream_culture.mp3',
      licenseName: 'CC BY 3.0',
      licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
      attributionText: '"Dream Culture" by Kevin MacLeod (CC BY 3.0) – https://incompetech.com',
      sourceUrl: 'https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1400020',
    ),
    MusicTrack(
      id: 'ambient_atlantean_twilight',
      title: 'Atlantean Twilight',
      artist: 'Kevin MacLeod',
      genre: 'Ambient/Chill',
      assetPath: 'assets/music/ambient_atlantean_twilight.mp3',
      licenseName: 'CC BY 3.0',
      licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
      attributionText: '"Atlantean Twilight" by Kevin MacLeod (CC BY 3.0) – https://incompetech.com',
      sourceUrl: 'https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100326',
    ),
  ];
}
