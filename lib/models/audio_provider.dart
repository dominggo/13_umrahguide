import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPath;
  bool _isPlaying = false;

  final StreamController<void> _trackCompleteController =
      StreamController<void>.broadcast();

  bool get isPlaying => _isPlaying;
  String? get currentPath => _currentPath;

  /// Fires once whenever the current track finishes playing naturally.
  Stream<void> get onTrackComplete => _trackCompleteController.stream;

  AudioProvider() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _currentPath = null;
        _trackCompleteController.add(null);
      }
      notifyListeners();
    });
  }

  Future<void> play(String assetPath) async {
    if (_currentPath == assetPath && _isPlaying) {
      await _player.pause();
      return;
    }
    _currentPath = assetPath;
    await _player.stop();
    await _player.setAsset(assetPath);
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPath = null;
    _isPlaying = false;
    notifyListeners();
  }

  bool isCurrentlyPlaying(String path) => _currentPath == path && _isPlaying;

  @override
  void dispose() {
    _player.dispose();
    _trackCompleteController.close();
    super.dispose();
  }
}
