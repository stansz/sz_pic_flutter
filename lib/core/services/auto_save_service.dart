import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/project.dart';

/// Service for managing auto-save functionality with timer debouncing
class AutoSaveService extends ChangeNotifier {
  String? _activeProjectId;
  ProjectType? _activeProjectType;
  Timer? _autoSaveTimer;
  Future<void> Function()? _saveCallback;
  Duration _autoSaveDelay = const Duration(seconds: 30);
  bool _isSaving = false;

  /// Currently active project ID
  String? get activeProjectId => _activeProjectId;

  /// Currently active project type
  ProjectType? get activeProjectType => _activeProjectType;

  /// Auto-save delay duration
  Duration get autoSaveDelay => _autoSaveDelay;

  /// Whether a save is currently in progress
  bool get isSaving => _isSaving;

  /// Set auto-save delay duration
  set autoSaveDelay(Duration duration) {
    _autoSaveDelay = duration;
  }

  /// Start auto-save for a project
  void startAutoSave({
    required String projectId,
    required ProjectType type,
    required Future<void> Function() saveCallback,
  }) {
    _activeProjectId = projectId;
    _activeProjectType = type;
    _saveCallback = saveCallback;

    debugPrint('AutoSaveService: Started auto-save for project $projectId (type: $type)');
    resetTimer();
  }

  /// Reset the auto-save timer (called on any user interaction)
  void resetTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, triggerSave);
    debugPrint('AutoSaveService: Timer reset for $_activeProjectId, will save in ${_autoSaveDelay.inSeconds} seconds');
  }

  /// Trigger save immediately (manual or timer callback)
  Future<void> triggerSave() async {
    if (_saveCallback == null || _isSaving) {
      debugPrint('AutoSaveService: Save skipped - callback: ${_saveCallback != null}, isSaving: $_isSaving');
      return;
    }

    _isSaving = true;
    notifyListeners();

    try {
      debugPrint('AutoSaveService: Saving project $_activeProjectId');
      await _saveCallback!();
      debugPrint('AutoSaveService: Successfully saved project $_activeProjectId');
    } catch (e, stackTrace) {
      debugPrint('AutoSaveService: Error saving project: $e');
      debugPrint('AutoSaveService: Stack trace: $stackTrace');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Stop auto-save (called when editor is disposed)
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _activeProjectId = null;
    _activeProjectType = null;
    _saveCallback = null;
    _isSaving = false;
    debugPrint('AutoSaveService: Stopped auto-save');
  }

  /// Trigger save immediately without waiting for timer
  Future<void> saveNow() async {
    _autoSaveTimer?.cancel();
    await triggerSave();
  }

  @override
  void dispose() {
    stopAutoSave();
    super.dispose();
  }
}
