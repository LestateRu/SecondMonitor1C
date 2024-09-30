import 'dart:convert';
import 'dart:io';

import 'package:second_monitor/Model/CheckItem.dart';
import 'package:second_monitor/Model/LoyaltyProgram.dart';
import 'package:second_monitor/Model/PaymentQRCode.dart';
import 'package:second_monitor/Model/Summary.dart';

class WebSocketService {
  WebSocket? _webSocket;
  late Function(dynamic message) _onDataReceived;

  // Set callback
  void setOnDataReceived(Function(dynamic message) callback) {
    _onDataReceived = callback;
  }

  // Connect to WebSocket
  void connect(String url) async {
    try {
      _webSocket = await WebSocket.connect(url);
      _listenToMessages();
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  // Listen to incoming messages
  void _listenToMessages() {
    _webSocket?.listen((message) {
      _onDataReceived(message); // Передаем сообщение в callback
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  // Disconnect from WebSocket
  void disconnect() {
    _webSocket?.close();
  }
}
