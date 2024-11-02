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
    _videoController = WinVideoPlayerController.file(File(videoPath));
    try {
      await _videoController.initialize();
      _isInitialized = true;
      log('VideoManager. Video initialized.');

      _videoController.addListener(() {
        if (_videoController.value.position >= _videoController.value.duration) {
         log('VideoManager. Video ended, restarting...');
          _restartVideoWithDelay();
        }
      });
      play();
    } catch (error) {
      log('VideoManager. Error initializing video: $error');
    }
  }

  Future<void> _restartVideoWithDelay() async {
    // Останавливаем видео на случай, если оно зависло
    _videoController.pause();
    // Добавляем небольшую задержку перед перезапуском
    await Future.delayed(Duration(milliseconds: 500));
    _videoController.seekTo(Duration.zero); // Возвращаем видео к началу
    play(); // Снова запускаем видео
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

  Future<void> checkAndUpdateVideo(Brend brend) async {
    try {
      // Заменяем имя файла в зависимости от бренда
      final String fileUrl = 'https://sportpoint.ru/bitrix/upload/SecondMonitor${brend.brendName}.mp4';
      final String localFilePath = 'assets/sample_video.mp4';

      final response = await http.head(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        final String? lastModifiedHeader = response.headers['last-modified'];
        if (lastModifiedHeader != null) {
          DateTime serverModTime = HttpDate.parse(lastModifiedHeader);

          final localFile = File(localFilePath);
          if (!localFile.existsSync()) {
            // Локальный файл отсутствует, загружаем новый файл
            await _downloadAndReplaceFile(fileUrl, localFilePath);
          } else {
            DateTime localModTime = localFile.lastModifiedSync();

            if (serverModTime.isAfter(localModTime)) {
              // Файл на сервере новее, загружаем и заменяем файл
              await _downloadAndReplaceFile(fileUrl, localFilePath);
            } else {
              // Локальный файл актуален
              log('VideoManager. Локальный файл актуален.');
            }
          }
        } else {
          log('VideoManager. Заголовок Last-Modified отсутствует.');
        }
      } else {
        log('VideoManager. Ошибка при обращении к серверу: ${response.statusCode}');
      }
    } catch (e) {
      log('VideoManager. Ошибка при проверке или обновлении файла: $e');
    }
  }

  // Метод для загрузки и замены файла
  Future<void> _downloadAndReplaceFile(String fileUrl, String localFilePath) async {
    try {
      // Отправляем запрос для получения файла
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        // Сохраняем загруженный файл
        final localFile = File(localFilePath);
        await localFile.writeAsBytes(response.bodyBytes);
        log('VideoManager. Файл успешно обновлён.');
      } else {
        log('VideoManager. Ошибка при загрузке файла: ${response.statusCode}');
      }
    } catch (e) {
      log('VideoManager. Ошибка при загрузке файла: $e');
    }
  }
}