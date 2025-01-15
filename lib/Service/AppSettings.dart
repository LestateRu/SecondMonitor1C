import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  bool isFullScreen;
  String selectedBrand;
  bool isVideoFromInternet; // Новый флаг источника видео
  String videoFilePath; // Новый путь к видеофайлу

  AppSettings({
    required this.isFullScreen,
    required this.selectedBrand,
    required this.isVideoFromInternet,
    required this.videoFilePath,
  });

  // Метод для загрузки настроек
  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Если настройки не сохранены, использовать значения по умолчанию
    bool isFullScreen = prefs.getBool('isFullScreen') ?? false;
    String selectedBrand = prefs.getString('selectedBrand') ?? 'SP';
    bool isVideoFromInternet = prefs.getBool('isVideoFromInternet') ?? true;
    String videoFilePath = prefs.getString('videoFilePath') ?? '';

    return AppSettings(
      isFullScreen: isFullScreen,
      selectedBrand: selectedBrand,
      isVideoFromInternet: isVideoFromInternet,
      videoFilePath: videoFilePath,
    );
  }

  // Метод для сохранения настроек
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFullScreen', isFullScreen);
    await prefs.setString('selectedBrand', selectedBrand);
    await prefs.setBool('isVideoFromInternet', isVideoFromInternet);
    await prefs.setString('videoFilePath', videoFilePath);
  }
}