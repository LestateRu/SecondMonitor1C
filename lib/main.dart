import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import 'package:second_monitor/View/second_monitor.dart';
import 'package:second_monitor/Service/logger.dart';
import 'SettingsWindow.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:hotkey_manager/hotkey.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll(); // Очистка всех горячих клавиш
  await loadSettings(); // Загрузка настроек при старте
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<bool> _updateCheckFuture = _checkForUpdateWindows();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: FutureBuilder<bool>(
        future: _updateCheckFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: Text('Обновление')),
              body: Center(child: Text('Идет проверка обновлений')),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: Text('Ошибка')),
              body: Center(child: Text('Ошибка проверки обновлений')),
            );
          } else if (snapshot.data == false) {
            return MainScreen(); // Основная страница приложения
          } else {
            return Scaffold(
              appBar: AppBar(title: Text('Обновление')),
              body: Center(child: Text('Обновление доступно')),
            );
          }
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    _registerHotKey();
  }

  @override
  void dispose() {
    hotKeyManager.unregisterAll(); // Отмена регистрации горячих клавиш
    super.dispose();
  }

  void _registerHotKey() async {
    final hotKey = HotKey(
      KeyCode.keyH,
      modifiers: [KeyModifier.control],
      scope: HotKeyScope.system, // Глобальная область действия
    );

    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        _openSettingsWindow();
      },
    );
  }

  void _openSettingsWindow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SettingsWindow();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecondMonitor();
  }
}

Future<bool> _checkForUpdateWindows() async {
  String currentVersion = '1.0.1';
  const String versionUrl = 'http://1c.sportpoint.ru:5055/seconMonitor/version.json';

  try {
    final response = await http.get(Uri.parse(versionUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String latestVersion = data['latest_version'];
      final String updateUrl = data['update_url_windows'];

      if (latestVersion != currentVersion) {
        _showUpdateDialogWindows(updateUrl);
        return true;
      }
    } else {
      log('main. Ошибка проверки обновления для Windows. Код: ${response.statusCode}');
    }
  } catch (e) {
    log('main.Произошла ошибка при проверке обновления для Windows: $e');
  }
  return false; // Если нет обновлений или произошла ошибка
}

void _showUpdateDialogWindows(String updateUrl) {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Доступно обновление'),
        content: Text('Доступна новая версия. Хотите обновить сейчас?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadAndInstallUpdateWindows(updateUrl);
            },
            child: Text('Обновить'),
          ),
        ],
      );
    },
  );
}

Future<void> _downloadAndInstallUpdateWindows(String updateUrl) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/app_update.exe';

  try {
    final response = await http.get(Uri.parse(updateUrl));
    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      log('main. Обновление загружено: $filePath');
      await _installAndRestart(filePath);
    } else {
      log('main. Ошибка загрузки обновления. Код: ${response.statusCode}');
    }
  } catch (e) {
    log('main. Произошла ошибка при загрузке обновления: $e');
  }
}

Future<void> _installAndRestart(String filePath) async {
  final shell = Shell();

  try {
    await shell.run('''
      taskkill /IM app.exe /F
    ''');

    await shell.run('''
      start $filePath
    ''');

    exit(0);
  } catch (e) {
    log('main. Ошибка при установке: $e');
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> loadSettings() async {
  final directory = await getApplicationDocumentsDirectory();
  final settingsFile = File('${directory.path}/settings.json');

  if (await settingsFile.exists()) {
    final settingsJson = await settingsFile.readAsString();
    // Здесь можно загрузить данные настроек в соответствующие переменные
  }
}