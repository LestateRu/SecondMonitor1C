import 'package:flutter/material.dart';
import 'View/second_monitor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SecondMonitor(),
    );
  }
}
