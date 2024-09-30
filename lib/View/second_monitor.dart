import 'dart:convert';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:second_monitor/Service/WebSocketService.dart';
import 'package:second_monitor/Model/CheckItem.dart';
import 'package:second_monitor/Model/LoyaltyProgram.dart';
import 'package:second_monitor/Model/PaymentQRCode.dart';
import 'package:second_monitor/Model/Summary.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class SecondMonitor extends StatefulWidget {
  @override
  _SecondMonitorState createState() => _SecondMonitorState();
}

class _SecondMonitorState extends State<SecondMonitor> {
  late WebSocketService _webSocketService;
  LoyaltyProgram? _loyaltyProgram;
  Summary? _summary;
  List<CheckItem> _checkItems = [];
  PaymentQRCode? _paymentQRCode;

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    // Инициализация WebSocket
    _webSocketService = WebSocketService();
    _webSocketService.setOnDataReceived(_onDataReceived);
    _webSocketService.connect('ws://localhost:8080/ws/');

    // Инициализация видеоплеера
    _initializeVideo();

    // Полноэкранный режим
    _initFullScreen();
  }

  void _initFullScreen() async {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager
          .setFullScreen(true); // Устанавливаем полноэкранный режим
    });
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.file(
      File('C:\\video\\sample_video.mp4'), // Убедитесь, что путь корректный
    )..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoController.play();
          _videoController.setLooping(true);
        });
      });
  }

  // Callback для получения данных через WebSocket
  void _onDataReceived(dynamic message) {
    try {
      var jsonData = jsonDecode(message);

      var loyaltyProgram = jsonData['loyaltyProgram'] != null
          ? LoyaltyProgram.fromJson(jsonData['loyaltyProgram'])
          : null;

      var summary = jsonData['summary'] != null
          ? Summary.fromJson(jsonData['summary'])
          : null;

      var checkItems = jsonData['checkItems'] != null
          ? List<CheckItem>.from(
              jsonData['checkItems'].map((item) => CheckItem.fromJson(item)))
          : <CheckItem>[]; // Пустой список, если данных нет

      var paymentQRCode = jsonData['paymentQRCode'] != null &&
              jsonData['paymentQRCode']['qrCodeData'] != null
          ? PaymentQRCode.fromJson(jsonData['paymentQRCode'])
          : null;

      setState(() {
        _loyaltyProgram = loyaltyProgram;
        _summary = summary;
        _checkItems = checkItems;
        _paymentQRCode = paymentQRCode;
      });

      // Если все товары имеют пустое поле name, запускаем видео
      if (_shouldShowVideo()) {
        _videoController.play();
      } else {
        _videoController.pause();
      }
    } catch (e) {
      print("Error parsing message: $e");
    }
  }

  // Проверка, нужно ли показывать видео (если все CheckItems пустые)
  bool _shouldShowVideo() {
    return _checkItems.isEmpty ||
        _checkItems.every((item) => item.name.isEmpty);
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _shouldShowVideo()
          ? _buildVideoPlayer() // Показываем видео на весь экран
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFD92038), width: 10),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Header with image
                  Center(
                    child: Image.network(
                      'https://jnsonline.ru/images/jns_logo.png',
                      width: 120,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Row with LoyaltyProgram, PaymentSection, and PaymentSummary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loyalty program (left)
                      Expanded(
                        child: _buildLoyaltyProgram(),
                      ),

                      // Payment section (center) with fixed width
                      if (_paymentQRCode != null &&
                          _paymentQRCode!.qrCodeData.isNotEmpty)
                        SizedBox(
                          width: 150, // Фиксированная ширина для QR-кода
                          child: _buildPaymentSection(),
                        ),

                      // Payment summary (right)
                      Expanded(
                        child: _buildPaymentSummary(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Table of items
                  Expanded(
                    child: _buildItemsTable(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Видеоплеер на весь экран с черным фоном
  Widget _buildVideoPlayer() {
    return _isVideoInitialized
        ? Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black, // Черный фон для всего контейнера
            child: FittedBox(
              fit: BoxFit
                  .contain, // Видео сохраняет пропорции, черный фон вокруг
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          )
        : Center(child: CircularProgressIndicator());
  }

  Widget _buildLoyaltyProgram() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ПРОГРАММА ЛОЯЛЬНОСТИ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          if (_loyaltyProgram != null) ...[
            _buildLoyaltyItem('Уровень:', _loyaltyProgram!.level),
            _buildLoyaltyItem(
                'Количество бонусов:', '${_loyaltyProgram!.bonusPoints}'),
            _buildLoyaltyItem('До перехода на следующий уровень:',
                '${_loyaltyProgram!.pointsToNextLevel}'),
          ] else ...[
            Text('Загрузка...'),
          ],
        ],
      ),
    );
  }

  Widget _buildLoyaltyItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return _paymentQRCode != null && _paymentQRCode!.qrCodeData.isNotEmpty
        ? Container(
            width: 150,
            height: 200,
            decoration: BoxDecoration(
              color: Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: QrImageView(
                data: _paymentQRCode!.qrCodeData,
                size: 150.0,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
          )
        : SizedBox.shrink();
  }

  Widget _buildPaymentSummary() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentSummaryItem('ИТОГО', ''),
          if (_summary != null) ...[
            _buildPaymentSummaryItem(
                'Количество позиций:', '${_summary!.totalItems}'),
            _buildPaymentSummaryItem(
                'Сумма скидки:', '${_summary!.discountAmount}'),
            _buildPaymentSummaryItem(
                'За покупку начисляется:', '${_summary!.bonusForPurchase}'),
            _buildPaymentSummaryItem('СУММА ЧЕКА:', '${_summary!.totalAmount}',
                isBold: true),
          ] else ...[
            Text('Загрузка...'),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryItem(String label, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            DataColumn(label: Text('№')),
            DataColumn(label: Text('НАИМЕНОВАНИЕ')),
            DataColumn(label: Text('АРТИКУЛ')),
            DataColumn(label: Text('РАЗМЕР')),
            DataColumn(label: Text('КОЛ-ВО')),
            DataColumn(label: Text('СУММА')),
          ],
          rows: _checkItems.isNotEmpty
              ? _checkItems.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  CheckItem item = entry.value;
                  return DataRow(cells: [
                    DataCell(Text('$index')),
                    DataCell(Text(item.name)),
                    DataCell(Text(item.article)),
                    DataCell(Text(item.size)),
                    DataCell(Text('${item.quantity}')),
                    DataCell(Text('${item.amount}')),
                  ]);
                }).toList()
              : [
                  DataRow(cells: [
                    DataCell(Text('1')),
                    DataCell(Text('Загрузка...')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                    DataCell(Text('')),
                  ]),
                ],
        ),
      ),
    );
  }
}
