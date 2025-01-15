import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // Для получения локального пути
import 'package:video_player_win/video_player_win.dart';
import 'package:second_monitor/Service/logger.dart';

class VideoManager {
  late WinVideoPlayerController _videoController;
  bool _isInitialized = false;

  Future<void> initialize({
    required bool isVideoFromInternet,
    required String videoSource,
  }) async {
    try {
      log('Initializing video from ${isVideoFromInternet ? "URL" : "local file"}: $videoSource');

      if (isVideoFromInternet) {
        // Используем URL для воспроизведения
        _videoController = WinVideoPlayerController.network(videoSource);
      } else {
        // Используем локальный файл
        final videoFile = File(videoSource);
        _videoController = WinVideoPlayerController.file(videoFile);
      }

      await _videoController.initialize();
      _isInitialized = true;

      _videoController.addListener(() {
        if (_videoController.value.position >= _videoController.value.duration) {
          _restartVideoWithDelay();
        }
      });

      log('Video initialized successfully.');
      play();
    } catch (error) {
      log('Error initializing video: $error');
    }
  }

  Future<void> _restartVideoWithDelay() async {
    _videoController.pause();
    await Future.delayed(Duration(milliseconds: 500));
    _videoController.seekTo(Duration.zero);
    play();
  }

  bool get isInitialized => _isInitialized;

  WinVideoPlayerController get controller => _videoController;

  void play() {
    if (_isInitialized) {
      log('Playing video...');
      _videoController.play();
    } else {
      log('Video not initialized yet.');
    }
  }

  void pause() {
    if (_isInitialized) {
      log('Pausing video...');
      _videoController.pause();
    }
  }

  void dispose() {
    if (_isInitialized) {
      _videoController.dispose();
    }
  }
}