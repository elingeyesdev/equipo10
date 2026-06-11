import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'local_database.dart';
import '../models/reporte_model.dart';

class EncuestaService {
  final ApiService _api = ApiService();
  final LocalDatabase _db = LocalDatabase();

  /// Verifica si el usuario tiene encuestas pendientes de operativos cerrados.
  Future<List<ReporteModel>> getEncuestasPendientes(String usuarioId) async {
    try {
      final response = await _api.client.get('/encuestas/pendientes/$usuarioId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ReporteModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[EncuestaService] Error al obtener pendientes: $e');
      return [];
    }
  }

  /// Envía la encuesta al servidor.
  /// Si falla (sin red), guarda en cola local y retorna true (no bloquea el flujo).
  Future<bool> enviarEncuesta({
    required String reporteId,
    required String usuarioId,
    required int puntuacion,
    String? comentario,
  }) async {
    try {
      final response = await _api.client.post('/encuestas', data: {
        'reporte_id': reporteId,
        'usuario_id': usuarioId,
        'puntuacion': puntuacion,
        'comentario': comentario,
      });
      if (response.statusCode == 201 || response.statusCode == 200) return true;
      // 409 = ya fue evaluado anteriormente; se considera éxito silencioso
      if (response.statusCode == 409) return true;
      return false;
    } catch (e) {
      debugPrint('[EncuestaService] Sin red, guardando en cola offline: $e');
      // Guardar en cola para reintento posterior
      await _db.saveEncuestaPendiente(
        reporteId: reporteId,
        usuarioId: usuarioId,
        puntuacion: puntuacion,
        comentario: comentario,
      );
      return true; // No bloqueamos el flujo del usuario
    }
  }

  /// Reintenta enviar las encuestas que quedaron en la cola offline.
  /// Llamar cuando la conectividad se restaure.
  Future<void> sincronizarPendientes() async {
    final pendientes = await _db.getEncuestasPendientes();
    if (pendientes.isEmpty) return;

    debugPrint('[EncuestaService] Sincronizando ${pendientes.length} encuesta(s) pendiente(s)...');
    for (final enc in pendientes) {
      try {
        final response = await _api.client.post('/encuestas', data: {
          'reporte_id': enc['reporte_id'],
          'usuario_id': enc['usuario_id'],
          'puntuacion': enc['puntuacion'],
          'comentario': enc['comentario'],
        });
        // Eliminar de la cola si fue exitoso o si ya existía (409)
        if (response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 409) {
          await _db.deleteEncuestaPendiente(enc['id'] as int);
          debugPrint('[EncuestaService] Encuesta ${enc['id']} sincronizada.');
        }
      } catch (_) {
        // Mantenemos en cola para el próximo intento
        break;
      }
    }
  }
}
