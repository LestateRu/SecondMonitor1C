import 'dart:io';

void log(String message) {
  final logFile = File('app_logs.txt');
  logFile.writeAsStringSync('${DateTime.now()}: $message\n', mode: FileMode.append);
}
