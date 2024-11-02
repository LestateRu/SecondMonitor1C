import 'package:second_monitor/Model/Brend.dart';
import 'package:video_player_win/video_player_win.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class VideoManager {
  late WinVideoPlayerController _videoController;
  bool _isInitialized = false;

  Future<void> initialize(String videoPath) async {
    _videoController = WinVideoPlayerController.file(File(videoPath));
    try {
      await _videoController.initialize();
      _isInitialized = true;
      //print('Video initialized.');

      _videoController.addListener(() {
        if (_videoController.value.position >= _videoController.value.duration) {
         // print('Video ended, restarting...');
          _restartVideoWithDelay();
        }
      });
      play();
    } catch (error) {
      //print('Error initializing video: $error');
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
      print('Playing video...');
      _videoController.play();
    } else {
      print('Video not initialized yet.');
    }
  }

  void pause() {
    if (_isInitialized) {
      print('Pausing video...');
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
              print('Локальный файл актуален.');
            }
          }
        } else {
          print('Заголовок Last-Modified отсутствует.');
        }
      } else {
        print('Ошибка при обращении к серверу: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при проверке или обновлении файла: $e');
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
        print('Файл успешно обновлён.');
      } else {
        print('Ошибка при загрузке файла: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке файла: $e');
    }
  }
}