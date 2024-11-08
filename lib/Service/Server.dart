import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:second_monitor/Service/logger.dart';

class Server {
  String receivedDataFrom1C = '';

  Future<void> startServer() async {
    try {
      await Future.wait([
        _startHttpServer(),
        _startWebSocketServer(),
      ]);
    } catch (e) {
     log('WebSocketServer. Ошибка при запуске серверов: $e');
    }
  }

  Future<void> _startHttpServer() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 4001);
    log('WebSocketServer. HTTP сервер запущен на http://localhost:4001/api/');

    await for (HttpRequest request in server) {
      if (request.method == 'POST' && request.uri.path == '/api/') {
        await _handleHttpRequestFrom1C(request);
      } else {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Некорректный запрос')
          ..close();
      }
    }
  }

  Future<void> _handleHttpRequestFrom1C(HttpRequest request) async {
    try {
      final content = await utf8.decoder.bind(request).join();
      receivedDataFrom1C = content;
      log('WebSocketServer. Получены данные от 1С: $receivedDataFrom1C');

      request.response
        ..statusCode = HttpStatus.ok
        ..write('Данные получены')
        ..close();
    } catch (e) {
      log('WebSocketServer. Ошибка при обработке HTTP-запроса от 1С: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Ошибка сервера')
        ..close();
    }
  }

  Future<void> _startWebSocketServer() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 4002);
    log('WebSocketServer. WebSocket сервер запущен на ws://localhost:4002/ws/');

    await for (HttpRequest request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocket socket = await WebSocketTransformer.upgrade(request);
        log('WebSocketServer. Клиент WebSocket подключен.');
        _sendJsonData(socket);
      } else {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Некорректный запрос')
          ..close();
      }
    }
  }

  void _sendJsonData(WebSocket socket) async {
    try {
      Timer.periodic(Duration(milliseconds: 500), (timer) {
        if (receivedDataFrom1C.isNotEmpty) {
          socket.add(receivedDataFrom1C);
         log('WebSocketServer. Отправлены данные клиенту: $receivedDataFrom1C');
          receivedDataFrom1C = '';
        }

        if (socket.readyState != WebSocket.open) {
          timer.cancel();
        }
      });
    } catch (e) {
      log('WebSocketServer. Ошибка при передаче данных по WebSocket: $e');
      socket.close(WebSocketStatus.internalServerError, 'Ошибка сервера');
    }
  }
}

void main() async {
  final server = Server();
  await server.startServer();
}