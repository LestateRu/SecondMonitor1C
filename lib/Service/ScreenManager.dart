import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:second_monitor/Service/logger.dart';

class ScreenManager {
  Future<void> moveToSecondScreen() async {
    final screens = await ScreenRetriever.instance.getAllDisplays();

    if (screens.length > 1) {
      final ferstScreen = screens[0];
      final secondScreen = screens[1];
      final translateX = ferstScreen.visiblePosition!.dx + 10.0;
      final translateY = ferstScreen.visiblePosition!.dy + secondScreen.visiblePosition!.dy;
      log('Данные экранов 1-й ${ferstScreen.visiblePosition} 2-й${secondScreen.visiblePosition} суммы верт ${translateX} гориз ${translateY}');
      final bounds = secondScreen.visiblePosition!.translate(translateX, translateY);

      await windowManager.setPosition(bounds);
      await windowManager.setAlwaysOnTop(false);
    } else {
      log('Второй экран не найден. Окно останется на текущем экране.');
    }
  }
}