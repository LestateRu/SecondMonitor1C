import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:second_monitor/Service/ScreenManager.dart';
import 'package:second_monitor/Service/VideoManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:second_monitor/Service/WebSocketService.dart';
import 'package:second_monitor/Model/CheckItem.dart';
import 'package:second_monitor/Model/LoyaltyProgram.dart';
import 'package:second_monitor/Model/PaymentQRCode.dart';
import 'package:second_monitor/Model/Summary.dart';
import 'package:second_monitor/Model/Brend.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:second_monitor/Service/logger.dart';
import 'package:second_monitor/Service/Server.dart';


class Settings {
  String brand;
  bool fullscreen;
  String videoPath;

  Settings({required this.brand, required this.fullscreen, required this.videoPath});

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      brand: json['brand'] ?? 'SP',
      fullscreen: json['fullscreen'] ?? false,
      videoPath: json['videoPath'] ?? 'C:\\SSM\\',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'fullscreen': fullscreen,
      'videoPath': videoPath,
    };
  }
}


class SecondMonitor extends StatefulWidget {
  @override
  _SecondMonitorState createState() => _SecondMonitorState();
}

class _SecondMonitorState extends State<SecondMonitor> {
  late Settings _settings;
  late WebSocketService _webSocketService;
  late Server _server;
  LoyaltyProgram? _loyaltyProgram;
  Summary? _summary;
  List<CheckItem> _checkItems = [];
  PaymentQRCode? _paymentQRCode;
  Brend? _brend;
  late VideoManager _videoManager;

  @override
  void initState() {
    super.initState();

    _server = Server();
    _server.startServer();
    _webSocketService = WebSocketService();
    _webSocketService.setOnDataReceived(_onDataReceived);
    _webSocketService.connect('ws://localhost:4002/ws/');
    _videoManager = VideoManager();
    _loadSettings().then((_) {
    _initializeVideo();
    _initFullScreen();});
  }

  /// Загружает настройки из SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? brand = prefs.getString('selectedBrand');
      bool? fullscreen = prefs.getBool('isFullScreen');
      String? videoPath = prefs.getString('videoFolder');

      setState(() {
        _settings = Settings(
          brand: brand ?? 'NSP',
          fullscreen: fullscreen ?? false,
          videoPath: videoPath ?? 'C:\\SSM\\',
        );
      });
    } catch (e) {
      print('Ошибка загрузки настроек: $e');
      _settings = Settings(
        brand: 'NSP',
        fullscreen: false,
        videoPath: 'C:\\SSM\\',
      );
    }
  }

  /// Сохраняет настройки в SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedBrand', _settings.brand);
    } catch (e) {
      print('Ошибка сохранения настроек: $e');
    }
  }

  void _initFullScreen() async {
    await windowManager.ensureInitialized();
    final screenManager = ScreenManager();
    await screenManager.moveToSecondScreen();
    await windowManager.setFullScreen(_settings.fullscreen);
  }


  void _initializeVideo() {
    String videoUrl = 'https://sportpoint.ru/upload/SecondMonitor/${_settings.brand}.mp4';
    _videoManager.initialize(videoUrl).then((_) {
      setState(() {});
    });
  }


  void _onDataReceived(dynamic message) {
    try {
      var jsonData = jsonDecode(message);

      var brend = jsonData['brend'] != null ? Brend.fromJson(jsonData['brend']) : null;

      setState(() {
        _brend = brend;
      });

      var loyaltyProgram = jsonData['loyaltyProgram'] != null
          ? LoyaltyProgram.fromJson(jsonData['loyaltyProgram'])
          : null;

      var summary = jsonData['summary'] != null ? Summary.fromJson(jsonData['summary']) : null;

      var checkItems = jsonData['checkItems'] != null
          ? List<CheckItem>.from(
          jsonData['checkItems'].map((item) => CheckItem.fromJson(item)))
          : <CheckItem>[];

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

      if (_shouldShowVideo()) {
        _videoManager.play();
      } else {
        _videoManager.pause();
      }

      _saveSettings();
    } catch (e) {
      log('SecondMonitor. Ошибка при обработке сообщения: $e');
    }
  }

  bool _shouldShowVideo() {
    return _checkItems.isEmpty || _checkItems.every((item) => item.name.trim().isEmpty);
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _videoManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _shouldShowVideo()
          ? _buildVideoPlayer()
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
                  Center(
                    child: _buildBrendLogo(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLoyaltyProgram(),
                      ),
                      if (_paymentQRCode != null &&
                          _paymentQRCode!.qrCodeData.isNotEmpty)
                        SizedBox(
                          width: 150,
                          child: _buildPaymentSection(),
                        ),
                      Expanded(
                        child: _buildPaymentSummary(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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

  Widget _buildBrendLogo() {
    String logoPath = 'assets/JNS.png';
    String brendLogo = _settings.brand;

      switch (brendLogo) {
        case 'ASP':
          logoPath = 'assets/ASP.png';
          break;
        case 'NSP':
          logoPath = 'assets/NSP.png';
          break;
        case 'SP':
          logoPath = 'assets/SP.png';
          break;
        case 'JNS':
          logoPath = 'assets/JNS.png';
          break;

    }

    return Image.asset(
      logoPath,
      width: 120,
      height: 80,
    );
  }

  Widget _buildVideoPlayer() {
    return _videoManager.isInitialized
        ? Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _videoManager.controller.value.size.width,
          height: _videoManager.controller.value.size.height,
          child: WinVideoPlayer(_videoManager.controller),
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
                'Количество баллов:', '${_loyaltyProgram!.bonusPoints}'),
            _buildLoyaltyItem('До перехода на следующий уровень:',
                '${_loyaltyProgram!.pointsToNextLevel}'),
            _buildLoyaltyItem('Сгорание баллов:', '${_loyaltyProgram!.dataEndBonus}')
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
      height: 250,
      decoration: BoxDecoration(
        color: Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'СБП',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          QrImageView(
            data: _paymentQRCode!.qrCodeData,
            size: 150.0,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
          SizedBox(height: 8),
          Text(
            'К оплате:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${_summary!.totalAmount}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    return Expanded( // Заменяем Container на Expanded
      child: Container(
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
      ),
    );
  }
}