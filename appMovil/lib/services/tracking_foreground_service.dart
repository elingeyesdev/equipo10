import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Punto de entrada del background isolate — DEBE ser una función top-level.
@pragma('vm:entry-point')
void startTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(_TrackingTaskHandler());
}

class _TrackingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // El GPS se maneja en el isolate principal (TrackingService).
    // Este handler solo mantiene vivo el proceso en Android.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Actualizar texto de notificación cada 30s si hace falta.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  /// Reenvía los taps de botones de notificación al isolate principal.
  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain(id);
  }
}

/// Gestiona el ciclo de vida del Foreground Service de tracking.
class TrackingForegroundService {
  static final TrackingForegroundService _instance =
      TrackingForegroundService._internal();
  factory TrackingForegroundService() => _instance;
  TrackingForegroundService._internal();

  static const int _serviceId = 256;

  void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'echoes_tracking_channel',
        channelName: 'Búsqueda activa',
        channelDescription: 'Echoes está rastreando tu ubicación',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<void> start({
    required String titulo,
    required String reporteId,
    required String usuarioId,
  }) async {
    // Solicitar permiso de notificaciones si es necesario
    final notifPerm = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPerm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Búsqueda activa',
        notificationText: titulo,
      );
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'Búsqueda activa',
      notificationText: titulo,
      notificationButtons: [
        const NotificationButton(id: 'btn_pausar', text: 'Pausar GPS'),
        const NotificationButton(id: 'btn_terminar', text: 'Terminar'),
      ],
      callback: startTrackingCallback,
    );
  }

  Future<void> updateText(String text) async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Búsqueda activa',
      notificationText: text,
    );
  }

  Future<void> stop() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }

  /// Escucha los botones de la notificación en el isolate principal.
  /// Retorna una función para desregistrar el callback.
  void Function() listenForActions({
    required void Function() onPausar,
    required void Function() onTerminar,
  }) {
    void callback(Object data) {
      if (data is String) {
        if (data == 'btn_pausar') onPausar();
        if (data == 'btn_terminar') onTerminar();
      }
    }
    FlutterForegroundTask.addTaskDataCallback(callback);
    return () => FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}
