import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Импортируем пакет для выбора файлов и папок
import 'second_monitor.dart'; // Подключаем SecondMonitor
import 'package:second_monitor/Service/AppSettings.dart'; // Импортируем класс для работы с настройками
import 'dart:async';

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({Key? key}) : super(key: key);

  @override
  _SettingsWindowState createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  bool isFullScreen = false; // Значение по умолчанию
  String selectedBrand = 'SP'; // Значение по умолчанию
  String videoFolder = ''; // Пустое значение по умолчанию
  bool isLoading = true; // Флаг загрузки настроек
  final List<String> availableBrands = ['SP', 'ASP', 'NSP', 'JNS'];
  Timer? _inactivityTimer;
  static const int inactivityDuration = 30; // Время бездействия в секундах.
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // Загрузка настроек
  void _loadSettings() async {
    AppSettings settings = await AppSettings.loadSettings();
    setState(() {
      isFullScreen = settings.isFullScreen;
      selectedBrand = settings.selectedBrand;
      videoFolder = settings.videoFolder;
      isLoading = false; // Настройки загружены
    });
  }

  // Метод для сохранения настроек
  void _saveSettings() {
    AppSettings settings = AppSettings(
      isFullScreen: isFullScreen,
      selectedBrand: selectedBrand,
      videoFolder: videoFolder,
    );
    settings.saveSettings();
  }

  // Метод для выбора папки
  Future<void> _selectFolder() async {
    // Открываем диалог выбора папки
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    // Если пользователь выбрал папку, обновляем состояние
    if (selectedDirectory != null) {
      setState(() {
        videoFolder = selectedDirectory;
      });
      _saveSettings(); // Сохраняем настройки после изменения
      _resetInactivityTimer();
    }
  }

  // Таймер бездействия
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: inactivityDuration), () {
      if (!_userInteracted) {
        _launchSecondMonitor(context);
      }
    });
  }

  void _resetInactivityTimer() {
    _userInteracted = true;
    _startInactivityTimer();
  }

  // Метод для запуска второго монитора
  void _launchSecondMonitor(BuildContext context) {
    _saveSettings(); // Сохраняем настройки перед запуском
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SecondMonitor()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _resetInactivityTimer,
      child: Scaffold(
        appBar: AppBar(title: const Text('Настройки приложения')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SwitchListTile(
                title: const Text('Полноэкранный режим'),
                value: isFullScreen,
                onChanged: (value) {
                  setState(() {
                    isFullScreen = value;
                  });
                  _saveSettings(); // Сохраняем настройки после изменения
                  _resetInactivityTimer();
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Выбор бренда:',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedBrand,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedBrand = newValue!;
                        });
                        _saveSettings(); // Сохраняем настройки после изменения
                        _resetInactivityTimer();
                      },
                      items: availableBrands.map<DropdownMenuItem<String>>((String brand) {
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Text(brand),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Папка для видеофайлов'),
                controller: TextEditingController(text: videoFolder),
                readOnly: true, // Сделать поле только для чтения
                onTap: _selectFolder, // Открыть диалог выбора папки
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _launchSecondMonitor(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text(
                  'Запустить приложение',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}