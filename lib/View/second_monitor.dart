import 'dart:convert';
import 'dart:io';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:second_monitor/Service/VideoManager.dart';
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


class SecondMonitor extends StatefulWidget {
  @override
  _SecondMonitorState createState() => _SecondMonitorState();
}

class _SecondMonitorState extends State<SecondMonitor> {
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
    _initializeVideo();
    _initFullScreen();
    //_scheduleDailyVideoCheck();
  }



  void _initFullScreen() async {
    try {
      await windowManager.ensureInitialized();
      List<Display> displays = await screenRetriever.getAllDisplays();
      await windowManager.setFullScreen(false);
      if (displays.length == 1) {
        Display secondDisplay = displays[1];
        var bounds = secondDisplay.bounds;
        await windowManager.setBounds(Rect.fromLTWH(
          bounds.left!.toDouble(),
          bounds.top!.toDouble(),
          bounds.width!.toDouble(),
          bounds.height!.toDouble(),
        ));

      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Ошибка'),
            content: Text('Второй экран не найден. Пожалуйста, подключите второй экран.'),
            actions: [
              TextButton(
                onPressed: () {
                  log('SecondMonitor. Второй монитор не подключен');
                  Navigator.of(context).pop();
                  windowManager.close();
                },
                child: Text('Закрыть'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      log ("SecondMonitor. Ошибка инициализации экрана: $e");
    }
  }


  void _initializeVideo() {
    if (_brend != null) {
      _videoManager.initialize('C:\\SSM\\${_brend?.brendName}.mp4').then((value) {
        setState(() {});
      });
    } else {
      _videoManager.initialize('C:\\SSM\\SP.mp4').then((value) {
        setState(() {});
      });
    }
  }

  // void _scheduleDailyVideoCheck() {
  //   DateTime now = DateTime.now();
  //   DateTime targetTime = DateTime(now.year, now.month, now.day, 9, 0);
  //
  //   if (now.isAfter(targetTime)) {
  //     targetTime = targetTime.add(Duration(days: 1));
  //   }
  //
  //   Duration initialDelay = targetTime.difference(now);
  //
  //   Timer(initialDelay, () {
  //     if (_brend != null) {
  //       _videoManager.checkAndUpdateVideo(_brend!);
  //     }
  //
  //     Timer.periodic(Duration(hours: 24), (timer) {
  //       if (_brend != null) {
  //         _videoManager.checkAndUpdateVideo(_brend!);
  //       }
  //     });
  //   });
  // }

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

      var summary = jsonData['summary'] != null
          ? Summary.fromJson(jsonData['summary'])
          : null;

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

    if (_brend != null) {
      switch (_brend!.brendName) {
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          if (_loyaltyProgram != null) ...[
            _buildLoyaltyItem('УРОВЕНЬ:', _loyaltyProgram!.level),
            _buildLoyaltyItem(
                'КОЛИЧЕСТВО БОНУСОВ:', '${_loyaltyProgram!.bonusPoints}'),
            _buildLoyaltyItem('ДО ПЕРЕХОДА НА СЛЕДУЮЩИЙ УРОВЕНЬ:',
                '${_loyaltyProgram!.pointsToNextLevel}'),
            _buildLoyaltyItem('СГОРАНИЕ БАЛОВ:', '${_loyaltyProgram!.dataEndBonus}')
          ] else ...[
            Text('Загрузка...'),
          ],
        ],
      ),
    );
  }

  Widget _buildLoyaltyItem(String label, String value, {bool isBold = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14),
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
          Text('ИТОГО',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          if (_summary != null) ...[
            _buildPaymentSummaryItem(
                'КОЛИЧЕСТВО ПОЗИЦИЙ:', '${_summary!.totalItems}'),
            _buildPaymentSummaryItem(
                'СУММА СКИДКИ:', '${_summary!.discountAmount}'),
            _buildPaymentSummaryItem(
                'ЗА ПОКУПКУ НАЧИСЛЯЕТСЯ:', '${_summary!.bonusForPurchase}'),
            _buildPaymentSummaryItem('СУММА ЧЕКА:', '${_summary!.totalAmount}', isBold: true),
          ] else ...[
            Text('Загрузка...'),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryItem(String label, String value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize),
          ),
        ],
      ),
    );
  }


  Widget _buildItemsTable() {
    return Expanded(
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

extension on Display {
  get bounds => null;
}