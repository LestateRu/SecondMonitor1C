import 'package:second_monitor/Model/Brend.dart';
import 'package:video_player_win/video_player_win.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:second_monitor/Service/logger.dart';

class VideoManager {
  late WinVideoPlayerController _videoController;
  bool _isInitialized = false;

  Future<void> initialize(String videoPath) async {
    log(videoPath);
    final File pathV = File(videoPath);
    log('After initialize file');
    _videoController = WinVideoPlayerController.file(pathV);
    log('after path');
    try {
      log('Start initialaze');
      await _videoController.initialize();
      log('After Init');
      _isInitialized = true;
      log('VideoManager. Video initialized.');

      _videoController.addListener(() {
        if (_videoController.value.position >=
            _videoController.value.duration) {
          _restartVideoWithDelay();
        }
      });
      play();
    } catch (error) {
      log('VideoManager. Error initializing video: $error');
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
      print('VideoManager. Playing video...');
      _videoController.play();
    } else {
      print('VideoManager. Video not initialized yet.');
    }
  }

  void pause() {
    if (_isInitialized) {
      print('VideoManager. Pausing video...');
      _videoController.pause();
    }
  }

  void dispose() {
    if (_isInitialized) {
      _videoController.dispose();
    }
  }
}