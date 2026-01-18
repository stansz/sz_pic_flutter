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
  bool _initializing = false; // Track if init is in progress
  Timer? _fadeTimer;
  static const _fadeStep = Duration(milliseconds: 50);

  MusicTrack? get currentTrack => _currentTrack;
  double get volume => _preferredVolume;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> init() async {
    if (_initialized) {
      debugPrint('[MusicService] init: already initialized, returning');
      return;
    }
    if (_initializing) {
      debugPrint('[MusicService] init: initialization already in progress, waiting...');
      // Wait for the existing init to complete
      while (_initializing && !_initialized) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      debugPrint('[MusicService] init: wait complete, initialized=$_initialized');
      return;
    }
    
    _initializing = true;
    debugPrint('[MusicService] init: starting audio session configuration');
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint(
        '[MusicService] init: complete. Bundled tracks: '
        '${MusicLibrary.tracks.map((t) => t.id).join(', ')}',
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[MusicService] init: Failed to init audio session: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<bool> playTrack(MusicTrack track, {double? initialVolume}) async {
    debugPrint('[MusicService] playTrack: starting for ${track.id}');
    await init();
    try {
      _cancelFade();
      
      // Stop current playback if a different track
      if (_currentTrack != null && _currentTrack!.id != track.id) {
        debugPrint('[MusicService] playTrack: stopping previous track ${_currentTrack!.id}');
        await _player.stop();
      }
      
      _currentVolume = initialVolume?.clamp(0.0, 1.0) ?? _currentVolume;
      
      // Ensure asset exists
      try {
        final ByteData data = await rootBundle.load(track.assetPath);
        debugPrint('[MusicService] playTrack: asset loaded successfully, size=${data.lengthInBytes}');
      } catch (e) {
        debugPrint('[MusicService] playTrack: Asset missing or failed to load: ${track.assetPath} - $e');
        return false;
      }
      
      debugPrint('[MusicService] playTrack: setting audio source and playing');
      await _player.setAudioSource(AudioSource.asset(track.assetPath));
      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(_currentVolume);
      _currentTrack = track;
      await _player.play();
      debugPrint('[MusicService] playTrack: play() completed for ${track.id}');
      return true;
    } catch (e, stack) {
      debugPrint('[MusicService] playTrack: Failed to play ${track.assetPath}: $e');
      debugPrint('[MusicService] playTrack: stack trace: $stack');
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
