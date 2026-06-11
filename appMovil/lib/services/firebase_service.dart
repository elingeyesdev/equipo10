import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../models/app_notification.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    // 1. Pedir permisos al usuario
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Permiso de notificaciones: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Obtener el token FCM del dispositivo
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await sendTokenToBackend(token);
      }

      // 3. Escuchar si el token cambia (ej. al restaurar datos)
      _messaging.onTokenRefresh.listen((newToken) {
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

  Future<void> sendTokenToBackend(String token) async {
    try {
      final userId = await _apiService.getCurrentUserId();
      if (userId == null) return;

      await _apiService.client.put('/auth/fcm-token/$userId', data: {
        'fcm_token': token,
      });
      debugPrint('Token FCM enviado al backend exitosamente');
    } catch (e) {
      debugPrint('Error enviando Token FCM al backend: $e');
    }
  }
}
