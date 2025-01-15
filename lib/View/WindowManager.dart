import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'second_monitor.dart';
import 'package:second_monitor/Service/AppSettings.dart';
import 'dart:async';

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({Key? key}) : super(key: key);

  @override
  _SettingsWindowState createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  bool isFullScreen = false;
  String selectedBrand = 'SP';
  String videoFilePath = '';
  bool isVideoFromInternet = true;
  bool isLoading = true;
  final List<String> availableBrands = ['SP', 'ASP', 'NSP', 'JNS'];
  Timer? _inactivityTimer;
  static const int inactivityDuration = 30;
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

  void _loadSettings() async {
    AppSettings settings = await AppSettings.loadSettings();
    setState(() {
      isFullScreen = settings.isFullScreen;
      selectedBrand = settings.selectedBrand;
      videoFilePath = settings.videoFilePath;
      isVideoFromInternet = settings.isVideoFromInternet;
      isLoading = false;
    });
  }

  void _saveSettings() {
    AppSettings settings = AppSettings(
      isFullScreen: isFullScreen,
      selectedBrand: selectedBrand,
      videoFilePath: videoFilePath,
      isVideoFromInternet: isVideoFromInternet,
    );
    settings.saveSettings();
  }

  Future<void> _selectVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        videoFilePath = result.files.single.path!;
      });
      _saveSettings();
      _resetInactivityTimer();
    }
  }

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

  void _launchSecondMonitor(BuildContext context) {
    _saveSettings();
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
                  _saveSettings();
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
                        _saveSettings();
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
              SwitchListTile(
                title: const Text('Видео воспроизводится из интернета'),
                value: isVideoFromInternet,
                onChanged: (value) {
                  setState(() {
                    isVideoFromInternet = value;
                  });
                  _saveSettings();
                  _resetInactivityTimer();
                },
              ),
              if (!isVideoFromInternet)
                TextField(
                  decoration: InputDecoration(labelText: 'Путь к видеофайлу'),
                  controller: TextEditingController(text: videoFilePath),
                  readOnly: true,
                  onTap: _selectVideoFile,
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
