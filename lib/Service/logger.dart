import 'dart:io';

void log(String message) {
  final logFile = File('app_logs.txt');
  _cleanupOldLogs(logFile);
  logFile.writeAsStringSync('${DateTime.now()}: $message\n', mode: FileMode.append);
}

void _cleanupOldLogs(File logFile) {
  if (!logFile.existsSync()) {
    return;
  }

  final lines = logFile.readAsLinesSync();
  final currentDate = DateTime.now();
  final threeDaysAgo = currentDate.subtract(Duration(days: 3));

  final newLines = lines.where((line) {
    final dateString = line.split(': ').first;
    final logDate = DateTime.tryParse(dateString);
    return logDate != null && logDate.isAfter(threeDaysAgo);
  }).toList();

  logFile.writeAsStringSync(newLines.join('\n') + '\n');
}
