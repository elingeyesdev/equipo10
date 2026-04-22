import 'api_service.dart';
import '../models/perfil_model.dart';

class VinculacionService {
  final ApiService _api = ApiService();

  /// Une al usuario a la búsqueda de una ficha (reporte).
  Future<void> unirseABusqueda({
    required String fichaId,
    required String usuarioId,
  }) async {
    final response = await _api.client.post('/reportes/$fichaId/voluntarios', data: {
      'usuario_id': usuarioId,
    });
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ya estás vinculado a esta búsqueda o hubo un error.');
    }
  }

  /// Verifica si el usuario ya está vinculado a una ficha y en estado 'buscando'.
  Future<bool> estaVinculado({
    required String fichaId,
    required String usuarioId,
  }) async {
    try {
      final response = await _api.client.get('/reportes/$fichaId/voluntarios/usuario/$usuarioId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final vinculado = response.data['vinculado'];
        final data = response.data['data'];
        
        // Solo consideramos activamente vinculado si el estado es buscando
        return vinculado == true && data != null && data['estado'] == 'buscando';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los perfiles de los voluntarios unidos a una ficha.
  Future<List<PerfilModel>> obtenerVoluntarios(String fichaId) async {
    try {
      final response = await _api.client.get('/reportes/$fichaId/voluntarios');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        
        // Filtramos solo los que están 'buscando'
        final activos = data.where((v) => v['estado'] == 'buscando').toList();
        
        // Formateamos usando PerfilModel para representar a los usuarios
        return activos.map((v) {
          final u = v['usuario'];
          return PerfilModel(
            id: u['id'],
            nombreCompleto: u['nombre'] ?? 'Sin nombre',
            telefono: u['telefono'] ?? 'Sin teléfono',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Permite al usuario abandonar la búsqueda manualmente
  Future<void> abandonarBusqueda({
    required String fichaId,
    required String usuarioId,
  }) async {
    final response = await _api.client.put('/reportes/$fichaId/voluntarios/abandonar/$usuarioId');
    if (response.statusCode != 200) {
      throw Exception('Fallo al abandonar la búsqueda.');
    }
  }
}
