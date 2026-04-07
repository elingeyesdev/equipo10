import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
}
