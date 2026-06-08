import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/reporte_model.dart'; // Usamos ReporteModel para leer el id y titulo del reporte

class EncuestaService {
  final ApiService _api = ApiService();

  /// Verifica si el usuario tiene encuestas pendientes de operativos cerrados
  Future<List<ReporteModel>> getEncuestasPendientes(String usuarioId) async {
    try {
      final response = await _api.client.get('/encuestas/pendientes/$usuarioId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ReporteModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener encuestas pendientes: $e');
      return [];
    }
  }

  /// Envia la respuesta de la encuesta
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
      return response.statusCode == 201;
    } catch (e) {
      print('Error al enviar encuesta: $e');
      return false;
    }
  }
}
