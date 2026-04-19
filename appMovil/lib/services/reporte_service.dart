import 'api_service.dart';
import '../models/reporte_model.dart';

class ReporteService {
  final ApiService _api = ApiService();

  /// Obtiene todos los reportes activos o pausados del Feed General.
  Future<List<ReporteModel>> obtenerReportes() async {
    final response = await _api.client.get('/reportes');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List data = response.data['data'];
      return data.map((e) => ReporteModel.fromMap(e)).toList();
    }
    throw Exception('No se pudieron obtener los reportes');
  }

  /// Obtiene solo los reportes creados por un usuario específico
  Future<List<ReporteModel>> obtenerMisReportes(String userId) async {
    final response = await _api.client.get('/reportes/usuario/$userId');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List data = response.data['data'];
      return data.map((e) => ReporteModel.fromMap(e)).toList();
    }
    throw Exception('Error al obtener mis reportes');
  }

  /// Obtiene un reporte específico detallado
  Future<ReporteModel?> obtenerReportePorId(String reporteId) async {
    final response = await _api.client.get('/reportes/$reporteId');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return ReporteModel.fromMap(response.data['data']);
    }
    return null;
  }

  /// Marca temporalmente el reporte como Oculto/Cerrado (Resuelto)
  Future<void> marcarResuelto(String reporteId) async {
    final response = await _api.client.put('/reportes/$reporteId/resuelto');
    if (response.statusCode != 200) {
      throw Exception('Fallo al cerrar o resolver el reporte.');
    }
  }

  // TODO: Agregar POST para crear reporte
}
