import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification.dart';

/// Servicio central de notificaciones de la app Echoes.
///
/// Es un **singleton**: solo existe una instancia durante toda la ejecución.
/// Se inicializa una vez en [main()] y luego se puede usar desde cualquier
/// ViewModel o servicio llamando a [NotificationService()].
///
/// ## Cómo agregar un nuevo tipo de notificación en el futuro
/// 1. Agrega el valor en [NotificationType] (en app_notification.dart).
/// 2. Define el canal en [_channels] si necesitas un canal distinto.
/// 3. Agrega el case en [_resolveChannel] si usas un canal distinto.
/// 4. Llama a `NotificationService().show(AppNotification(...))` desde el ViewModel.
///
/// ## Soporte por plataforma
/// - **Android**: notificaciones nativas en la barra del sistema
/// - **iOS**: notificaciones nativas (requiere permisos en Info.plist)
/// - **Web**: fallback silencioso (la UI usa SnackBar) — push web va en Commit 3
class NotificationService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── Plugin de notificaciones locales ──────────────────────────────────────
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Indica si el servicio fue inicializado correctamente.
  bool _initialized = false;

  // ── Definición de canales Android ─────────────────────────────────────────
  //
  // En Android 8+, cada notificación pertenece a un "canal" que el usuario
  // puede silenciar individualmente desde Ajustes. Agregar canales aquí para
  // agrupar tipos de notificación.

  static const _channelSearchActivity = AndroidNotificationChannel(
    'search_activity', // id único del canal
    'Actividad en búsquedas', // nombre visible al usuario
    description: 'Notificaciones sobre búsquedas en las que participas.',
    importance: Importance.high,
  );

  // Mapa de tipo → canal (para resolver fácilmente al hacer show())
  static const Map<NotificationType, AndroidNotificationChannel> _channels = {
    NotificationType.joinSearchConfirmation: _channelSearchActivity,
    // Agrega aquí los futuros tipos y sus canales
  };

  // ── ID de notificación por tipo ────────────────────────────────────────────
  //
  // Cada tipo tiene un ID fijo. Si quieres que coexistan múltiples notifs
  // del mismo tipo, usa IDs distintos (ej: timestamp o hash del fichaId).
  static const Map<NotificationType, int> _notifIds = {
    NotificationType.joinSearchConfirmation: 1001,
  };

  // ── Inicialización ─────────────────────────────────────────────────────────

  /// Inicializa el plugin y crea los canales en Android.
  ///
  /// Debe llamarse una sola vez al arrancar la app, en [main()].
  Future<void> initialize() async {
    // En web no hay notificaciones locales nativas — saltar inicialización.
    if (kIsWeb) {
      debugPrint(
          '[NotificationService] Web: inicialización omitida (sin soporte local).');
      _initialized = false;
      return;
    }

    // Configuración por plataforma
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // ícono de la notificación = ícono de la app
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final didInit = await _plugin.initialize(initSettings);
    if (didInit != true) {
      debugPrint(
          '[NotificationService] [WARN] El plugin no pudo inicializarse.');
      return;
    }

    // Crear canales en Android (en otras plataformas esto es ignorado)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      for (final channel in _channels.values.toSet()) {
        await androidPlugin.createNotificationChannel(channel);
      }
      // Solicitar permiso de notificaciones (Android 13+)
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[NotificationService] [OK] Inicializado correctamente.');
  }

  // ── Mostrar notificación ───────────────────────────────────────────────────

  /// Muestra una notificación nativa en el dispositivo.
  ///
  /// Si la app corre en web o el servicio no está inicializado,
  /// el método retorna silenciosamente (no crashea).
  Future<void> show(AppNotification notification) async {
    if (!_initialized) {
      debugPrint(
          '[NotificationService] show() ignorado: no inicializado o en web.');
      return;
    }

    final channel = _channels[notification.type] ?? _channelSearchActivity;
    final notifId = _notifIds[notification.type] ?? 9999;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      notifId,
      notification.title,
      notification.body,
      details,
    );

    debugPrint(
        '[NotificationService] Notificacion mostrada: "${notification.title}"');
  }
}
