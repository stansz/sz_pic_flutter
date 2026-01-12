import 'dart:async';
import 'dart:math';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/music_track.dart';
import 'music_library.dart';

class MusicService {
  final AudioPlayer _player = AudioPlayer();
  MusicTrack? _currentTrack;
  double _preferredVolume = 0.8;
  double _currentVolume = 0.8;
  bool _initialized = false;
  Timer? _fadeTimer;
  static const _fadeStep = Duration(milliseconds: 50);

  MusicTrack? get currentTrack => _currentTrack;
  double get volume => _preferredVolume;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint(
        '[MusicService] Bundled tracks: '
        '${MusicLibrary.tracks.map((t) => t.id).join(', ')}',
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[MusicService] Failed to init audio session: $e');
    }
  }

  Future<bool> playTrack(MusicTrack track, {double? initialVolume}) async {
    await init();
    try {
      _cancelFade();
      _currentVolume = initialVolume?.clamp(0.0, 1.0) ?? _currentVolume;
      // Ensure asset exists
      try {
        await rootBundle.load(track.assetPath);
      } catch (e) {
        debugPrint('[MusicService] Asset missing: ${track.assetPath} - $e');
        return false;
      }
      await _player.setAudioSource(AudioSource.asset(track.assetPath));
      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(_currentVolume);
      _currentTrack = track;
      await _player.play();
      return true;
    } catch (e) {
      debugPrint('[MusicService] Failed to play ${track.assetPath}: $e');
      return false;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    _cancelFade();
    await _player.stop();
  }

  Future<void> setVolume(double value) async {
    _cancelFade();
    _preferredVolume = value.clamp(0.0, 1.0);
    _currentVolume = _preferredVolume;
    await _player.setVolume(_preferredVolume);
  }

  void fadeToVolume(double targetVolume, Duration duration, {VoidCallback? onComplete}) {
    _cancelFade();
    final safeTarget = targetVolume.clamp(0.0, 1.0);
    if (duration <= Duration.zero || (_currentVolume - safeTarget).abs() < 0.001) {
      _currentVolume = safeTarget;
      _player.setVolume(_currentVolume);
      onComplete?.call();
      return;
    }
    final startVolume = _currentVolume;
    final delta = safeTarget - startVolume;
    int elapsedMs = 0;
    _fadeTimer = Timer.periodic(_fadeStep, (timer) {
      elapsedMs += _fadeStep.inMilliseconds;
      final progress = min(1.0, elapsedMs / duration.inMilliseconds);
      final nextVolume = (startVolume + delta * progress).clamp(0.0, 1.0);
      _currentVolume = nextVolume;
      _player.setVolume(nextVolume);
      if (progress >= 1.0) {
        _cancelFade();
        onComplete?.call();
      }
    });
  }

  void _cancelFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  Future<void> dispose() async {
    _cancelFade();
    await _player.dispose();
  }
}
