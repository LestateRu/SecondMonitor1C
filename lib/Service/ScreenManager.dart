import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class ScreenManager {
  Future<void> moveToSecondScreen() async {
    // Получаем список всех экранов через глобальный доступ
    final screens = await ScreenRetriever.instance.getAllDisplays();

    if (screens.length > 1) {
      // Второй экран
      final ferstScreen = screens[0];
      final secondScreen = screens[1];
      final translateX = ferstScreen.visiblePosition!.dx + secondScreen.visiblePosition!.dx;
      final translateY = ferstScreen.visiblePosition!.dy + secondScreen.visiblePosition!.dy;
      final bounds = secondScreen.visiblePosition!.translate(translateX, translateY);

      // Устанавливаем позицию окна на втором экране
      await windowManager.setPosition(bounds!);
      await windowManager.setAlwaysOnTop(false);
      //await windowManager.setFullScreen(true);
    } else {
      print('Второй экран не найден. Окно останется на текущем экране.');
    }
  }
}

extension on Display {
   get bounds => null;
}
