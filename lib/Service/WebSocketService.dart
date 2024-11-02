import 'dart:io';
import 'package:second_monitor/Service/logger.dart';

class WebSocketService {
  WebSocket? _webSocket;
  late Function(dynamic message) _onDataReceived;

  void setOnDataReceived(Function(dynamic message) callback) {
    _onDataReceived = callback;
  }

  void connect(String url) async {
    try {
      _webSocket = await WebSocket.connect(url);
      _listenToMessages();
    } catch (e) {
     log('WebSocketService. Error connecting to WebSocket: $e');
    }
  }

  void _listenToMessages() {
    _webSocket?.listen((message) {
      _onDataReceived(message);
    }, onError: (error) {
     log('WebSocketService. WebSocket error: $error');
    }, onDone: () {
     log('WebSocketService. WebSocket connection closed');
    });
  }

  void disconnect() {
    _webSocket?.close();
  }
}
