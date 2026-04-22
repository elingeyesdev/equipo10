import 'api_service.dart';
import '../models/categoria_model.dart';

class CategoriaService {
  final ApiService _api = ApiService();

  Future<List<CategoriaModel>> obtenerCategorias() async {
    final response = await _api.client.get('/categorias');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List data = response.data['data'];
      return data.map((e) => CategoriaModel.fromMap(e)).toList();
    }
    throw Exception('No se pudieron obtener las categorías');
  }
}
