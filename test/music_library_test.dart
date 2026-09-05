import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sz_pic_flutter/core/services/music_library.dart';

void main() {
  group('MusicLibrary', () {
    test('exposes the expected bundled tracks', () {
      expect(MusicLibrary.tracks.length, 3);
      expect(
        MusicLibrary.tracks.map((t) => t.title).toSet(),
        {'Carefree', 'Dream Culture', 'Atlantean Twilight'},
      );
    });

    test('every registered track file exists in assets', () {
      // Guards against wiring a track whose MP3 was never added (or renamed).
      for (final track in MusicLibrary.tracks) {
        final file = File(track.assetPath);
        expect(file.existsSync(), isTrue,
            reason: '${track.assetPath} referenced by MusicLibrary is missing');
      }
    });

    test('tracks carry CC BY attribution', () {
      for (final track in MusicLibrary.tracks) {
        expect(track.artist, 'Kevin MacLeod');
        expect(track.licenseName, contains('CC BY'));
        expect(track.attributionText, isNotEmpty);
        expect(track.licenseUrl, startsWith('https://creativecommons.org'));
      }
    });
  });
}
