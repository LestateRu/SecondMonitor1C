import 'dart:io';

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
     // print('Error connecting to WebSocket: $e');
    }
  }

  void _listenToMessages() {
    _webSocket?.listen((message) {
      _onDataReceived(message);
    }, onError: (error) {
     // print('WebSocket error: $error');
    }, onDone: () {
     // print('WebSocket connection closed');
    });
  }

  void disconnect() {
    _webSocket?.close();
  }
}
