import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../models/app_notification.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final ApiService _apiService = ApiService();

  Future<void> init() async {
    if (Firebase.apps.isEmpty) return;

    // 1. Pedir permisos al usuario
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Permiso de notificaciones: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Obtener el token FCM del dispositivo
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await sendTokenToBackend(token);
      }

      // 3. Escuchar si el token cambia (ej. al restaurar datos)
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        sendTokenToBackend(newToken);
      });

      // 4. Escuchar mensajes cuando la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            'Mensaje recibido en Foreground: ${message.notification?.title}');

        if (message.notification != null) {
          // Mostrar notificación local
          NotificationService().show(AppNotification(
            title: message.notification!.title ?? 'Nueva notificación',
            body: message.notification!.body ?? '',
            type: NotificationType.joinSearchConfirmation, // genérico por ahora
          ));
        }
      });
    }
  }

  /// Envía el token FCM al backend.
  /// [explicitUserId] permite pasarlo directamente tras login (cuando ya se
  /// tiene el ID pero aún no está guardado en SharedPreferences).
  Future<void> sendTokenToBackend([String? explicitUserId]) async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase no está inicializado. Omitiendo envío de Token FCM.');
        return;
      }

      final userId = explicitUserId ?? await _apiService.getCurrentUserId();
      if (userId == null) return;

      // Obtener el token FCM actual del dispositivo
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      await _apiService.client.put('/auth/fcm-token/$userId', data: {
        'fcm_token': fcmToken,
      });
      debugPrint('Token FCM enviado al backend exitosamente');
    } catch (e) {
      debugPrint('Error enviando Token FCM al backend: $e');
    }
  }
}
