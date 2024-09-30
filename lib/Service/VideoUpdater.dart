import 'dart:io';
import 'package:http/http.dart' as http;


// URL файла для скачивания
final String fileUrl = 'https://example.com/video/sample_video.mp4';
final String localFilePath = 'C:/video/sample_video.mp4';

// Метод для проверки и обновления файла
Future<void> _checkAndUpdateVideo() async {
  try {
    // Отправляем HEAD-запрос для получения заголовков (включая Last-Modified)
    final response = await http.head(Uri.parse(fileUrl));

    if (response.statusCode == 200) {
      // Получаем дату последней модификации файла на сервере
      final String? lastModifiedHeader = response.headers['last-modified'];
      if (lastModifiedHeader != null) {
        // Преобразуем строку даты в DateTime
        DateTime serverModTime = HttpDate.parse(lastModifiedHeader);

        // Проверяем дату последней модификации локального файла
        final localFile = File(localFilePath);
        if (!localFile.existsSync()) {
          print('Локальный файл отсутствует, загружаем новый файл...');
          await _downloadAndReplaceFile();
        } else {
          // Получаем дату последней модификации локального файла
          DateTime localModTime = localFile.lastModifiedSync();

          // Сравниваем даты
          if (serverModTime.isAfter(localModTime)) {
            print('Файл на сервере новее, загружаем и заменяем файл...');
            await _downloadAndReplaceFile();
          } else {
            print('Локальный файл актуален.');
          }
        }
      } else {
        print('Заголовок Last-Modified отсутствует, невозможно выполнить проверку по дате.');
      }
    } else {
      print('Ошибка при обращении к серверу: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при проверке или обновлении файла: $e');
  }
}

// Метод для загрузки и замены файла
Future<void> _downloadAndReplaceFile() async {
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