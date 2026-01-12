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
    MusicTrack(
      id: 'cinematic_rains_will_fall',
      title: 'Rains Will Fall',
      artist: 'Kevin MacLeod',
      genre: 'Cinematic',
      assetPath: 'assets/music/cinematic_rains_will_fall.mp3',
      licenseName: 'CC BY 3.0',
      licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
      attributionText: '"Rains Will Fall" by Kevin MacLeod (CC BY 3.0) – https://incompetech.com',
      sourceUrl: 'https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100409',
    ),
    MusicTrack(
      id: 'acoustic_porch_swing_days',
      title: 'Porch Swing Days (slower)',
      artist: 'Kevin MacLeod',
      genre: 'Acoustic/Folk',
      assetPath: 'assets/music/acoustic_porch_swing_days.mp3',
      licenseName: 'CC BY 3.0',
      licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
      attributionText: '"Porch Swing Days (slower)" by Kevin MacLeod (CC BY 3.0) – https://incompetech.com',
      sourceUrl: 'https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100619',
    ),
  ];
}
