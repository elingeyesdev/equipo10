import 'package:dio/dio.dart';
import '../models/cuadrante_model.dart';
import 'api_service.dart';

class CuadranteService {
  final ApiService _api = ApiService();

  Future<List<CuadranteModel>> getCuadrantes() async {
    try {
      final response = await _api.client.get('/cuadrantes');
      
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((m) => CuadranteModel.fromMap(m)).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener cuadrantes: $e');
      return [];
    }
  }

  Future<CuadranteModel?> detectarCuadrante(double lat, double lng) async {
    try {
      final response = await _api.client.post('/cuadrantes/detectar', data: {
        'lat': lat,
        'lng': lng,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return CuadranteModel.fromMap(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Error al detectar cuadrante: $e');
      return null;
    }
  }
}
