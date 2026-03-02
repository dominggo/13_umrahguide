import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioProvider extends ChangeNotifier {
  late AudioPlayer _player;
  String? _currentPath;
  bool _isPlaying = false;

  final StreamController<void> _trackCompleteController =
      StreamController<void>.broadcast();

  bool get isPlaying => _isPlaying;
  String? get currentPath => _currentPath;

  Stream<void> get onTrackComplete => _trackCompleteController.stream;

  AudioProvider() {
    _initPlayer();
  }

  void _initPlayer() {
    _player = AudioPlayer();
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

  Future<void> _reinitAndRecover() async {
    try {
      await _player.stop();
      await _player.dispose();
    } catch (_) {}
    _initPlayer();
  }

  Future<void> play(String assetPath) async {
    try {
      if (_currentPath == assetPath && _isPlaying) {
        await _player.pause();
        return;
      }
      _currentPath = assetPath;
      await _player.stop();
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      // try to recover once
      await _reinitAndRecover();
      try {
        await _player.setAsset(assetPath);
        await _player.play();
      } catch (e2) {
        // give up - clear current path so UI can recover
        _currentPath = null;
        rethrow;
      }
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _currentPath = null;
    _isPlaying = false;
    notifyListeners();
  }

  bool isCurrentlyPlaying(String path) => _currentPath == path && _isPlaying;

  @override
  void dispose() {
    try {
      _player.dispose();
    } catch (_) {}
    _trackCompleteController.close();
    super.dispose();
  }
}
