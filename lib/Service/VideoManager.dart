import 'package:video_player_win/video_player_win.dart';
import 'dart:io';

class VideoManager {
  late WinVideoPlayerController _videoController;
  bool _isInitialized = false;

  Future<void> initialize(String videoPath) async {
    _videoController = WinVideoPlayerController.file(File(videoPath));
    try {
      await _videoController.initialize();
      _isInitialized = true;
      _videoController.setLooping(true);
    } catch (error) {
      print('Error initializing video: $error');
    }
  }

  bool get isInitialized => _isInitialized;

  WinVideoPlayerController get controller => _videoController;

  void play() {
    if (_isInitialized) {
      _videoController.play();
    }
  }

  void pause() {
    if (_isInitialized) {
      _videoController.pause();
    }
  }

  void dispose() {
    if (_isInitialized) {
      _videoController.dispose();
    }
  }
}