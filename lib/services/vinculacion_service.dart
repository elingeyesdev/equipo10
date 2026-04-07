import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/perfil_model.dart';

class VinculacionService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Une al usuario a la búsqueda de una ficha.
  Future<void> unirseABusqueda({
    required String fichaId,
    required String usuarioId,
  }) async {
    // Verifica si ya existe la vinculación
    final existente = await _client
        .from('vinculaciones')
        .select()
        .eq('ficha_id', fichaId)
        .eq('usuario_id', usuarioId)
        .maybeSingle();

    if (existente != null) {
      throw Exception('Ya estás vinculado a esta búsqueda.');
    }

    await _client.from('vinculaciones').insert({
      'id': _uuid.v4(),
      'ficha_id': fichaId,
      'usuario_id': usuarioId,
    });
  }

  /// Verifica si el usuario ya está vinculado a una ficha.
  Future<bool> estaVinculado({
    required String fichaId,
    required String usuarioId,
  }) async {
    final data = await _client
        .from('vinculaciones')
        .select()
        .eq('ficha_id', fichaId)
        .eq('usuario_id', usuarioId)
        .maybeSingle();

    return data != null;
  }

  /// Obtiene los perfiles de los voluntarios unidos a una ficha.
  Future<List<PerfilModel>> obtenerVoluntarios(String fichaId) async {
    final bindings = await _client
        .from('vinculaciones')
        .select('usuario_id')
        .eq('ficha_id', fichaId);

    if ((bindings as List).isEmpty) return [];

    final userIds = bindings.map((e) => e['usuario_id'] as String).toList();

    final perfiles = await _client
        .from('perfiles')
        .select()
        .inFilter('id', userIds);

    return (perfiles as List).map((e) => PerfilModel.fromMap(e)).toList();
  }
}
