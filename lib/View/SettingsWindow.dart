import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsWindow extends StatefulWidget {
  @override
  _SettingsWindowState createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  final List<String> brands = ['ASP', 'NSP', 'SP', 'JNS']; // Доступные бренды
  String selectedBrand = 'ASP'; // Выбранный бренд по умолчанию
  bool showLoyalty = true; // Показывать ли виджет с системой лояльности
  String videoFolder = ''; // Путь к папке с видео

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedBrand = prefs.getString('selectedBrand') ?? 'SP';
      showLoyalty = prefs.getBool('showLoyalty') ?? true;
      videoFolder = prefs.getString('videoFolder') ?? 'C:\\SSM\\SP.mp4';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBrand', selectedBrand);
    await prefs.setBool('showLoyalty', showLoyalty);
    await prefs.setString('videoFolder', videoFolder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Выбор бренда
            Text('Выберите бренд:', style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: selectedBrand,
              onChanged: (value) {
                setState(() {
                  selectedBrand = value!;
                });
              },
              items: brands.map((brand) {
                return DropdownMenuItem(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // Переключатель системы лояльности
            SwitchListTile(
              title: Text('Показывать виджет с системой лояльности'),
              value: showLoyalty,
              onChanged: (value) {
                setState(() {
                  showLoyalty = value;
                });
              },
            ),
            SizedBox(height: 20),

            // Выбор папки для видео
            Text('Папка с видеофайлами:', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                Expanded(
                  child: Text(videoFolder.isEmpty ? 'Не выбрана' : videoFolder),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final directory = await FilePicker.platform.getDirectoryPath();
                    if (directory != null) {
                      setState(() {
                        videoFolder = directory;
                      });
                    }
                  },
                  child: Text('Выбрать'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Кнопка сохранения настроек
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _saveSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Настройки сохранены')),
                  );
                },
                child: Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SettingsWindow(),
  ));
}