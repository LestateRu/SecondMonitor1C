import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  bool isFullScreen;
  String selectedBrand;
  String videoFolder;

  AppSettings({
    required this.isFullScreen,
    required this.selectedBrand,
    required this.videoFolder,
  });

  // Метод для загрузки настроек
  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Если настройки не сохранены, использовать значения по умолчанию
    bool isFullScreen = prefs.getBool('isFullScreen') ?? false;
    String selectedBrand = prefs.getString('selectedBrand') ?? 'SP';
    String videoFolder = prefs.getString('videoFolder') ?? '';

    return AppSettings(
      isFullScreen: isFullScreen,
      selectedBrand: selectedBrand,
      videoFolder: videoFolder,
    );
  }

  // Метод для сохранения настроек
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFullScreen', isFullScreen);
    await prefs.setString('selectedBrand', selectedBrand);
    await prefs.setString('videoFolder', videoFolder);
  }
}
