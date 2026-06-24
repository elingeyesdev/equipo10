import 'package:dio/dio.dart';
import '../models/notificacion_model.dart';
import 'api_service.dart';

class NotificacionApiService {
  final ApiService _api = ApiService();

  Future<List<NotificacionModel>> obtenerNotificacionesUsuario(
      String usuarioId) async {
    try {
      final response =
          await _api.client.get('/notificaciones/usuario/$usuarioId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data['data'] ?? {};
        final List<dynamic> list = responseData['notificaciones'] ?? [];
        return list.map((json) => NotificacionModel.fromJson(json)).toList();
      }
      throw Exception('Error al cargar notificaciones');
    } catch (e) {
      throw Exception('Error de conexión al cargar notificaciones: $e');
    }
  }

  Future<bool> marcarComoLeida(String notificacionId) async {
    try {
      final response =
          await _api.client.put('/notificaciones/$notificacionId/leida');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> marcarTodasComoLeidas(List<String> ids) async {
    await Future.wait(ids.map((id) => marcarComoLeida(id)));
  }
}
