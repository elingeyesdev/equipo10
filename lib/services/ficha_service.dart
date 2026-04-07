import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ficha_model.dart';

class FichaService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();
  static const String _bucket = 'fotos_fichas';

  /// Obtiene todas las fichas activas (y pausadas, excluye cerradas del muro principal, a menos que se quiera así).
  /// Asumiremos que el feed general muestra activos y pausados o cerrados según la lógica anterior.
  Future<List<FichaModel>> obtenerFichas() async {
    final data = await _client
        .from('fichas')
        .select()
        .inFilter('estado', ['activo', 'cerrado', 'pausado'])
        .order('id', ascending: false);

    return (data as List).map((e) => FichaModel.fromMap(e)).toList();
  }

  /// Obtiene solo las fichas creadas por un usuario específico
  Future<List<FichaModel>> obtenerMisFichas(String userId) async {
    final data = await _client
        .from('fichas')
        .select()
        .eq('creado_por', userId)
        .order('id', ascending: false);

    return (data as List).map((e) => FichaModel.fromMap(e)).toList();
  }

  /// Obtiene una ficha por su ID.
  Future<FichaModel?> obtenerFichaPorId(String fichaId) async {
    final data =
        await _client.from('fichas').select().eq('id', fichaId).maybeSingle();
    if (data == null) return null;
    return FichaModel.fromMap(data);
  }

  /// Sube una imagen usando bytes (compatible con Web y Mobile).
  Future<String> subirImagen(XFile xFile) async {
    final extension = xFile.name.split('.').last.toLowerCase();
    final fileName = '${_uuid.v4()}.$extension';
    final filePath = 'public/$fileName';

    final bytes = await xFile.readAsBytes();

    await _client.storage.from(_bucket).uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: false,
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(filePath);
  }

  /// Crea una ficha nueva en la BD.
  Future<void> crearFicha({
    required String creadoPor,
    required String titulo,
    required String descripcion,
    String? fotoUrl,
    double? latitud,
    double? longitud,
    List<dynamic>? cuadrantes,
  }) async {
    await _client.from('fichas').insert({
      'id': _uuid.v4(),
      'creado_por': creadoPor,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
      'latitud': latitud,
      'longitud': longitud,
      'cuadrantes': cuadrantes ?? [],
      'estado': 'activo',
    });
  }

  /// Edita una ficha existente.
  Future<void> editarFicha({
    required String id,
    required String titulo,
    required String descripcion,
    String? fotoUrl,
  }) async {
    await _client.from('fichas').update({
      'titulo': titulo,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
    }).eq('id', id);
  }

  /// Actualiza los cuadrantes geométricos de la ficha.
  Future<void> actualizarCuadrantes(String id, List<dynamic> cuadrantes) async {
    await _client
        .from('fichas')
        .update({'cuadrantes': cuadrantes})
        .eq('id', id);
  }

  /// Elimina una ficha por ID.
  Future<void> eliminarFicha(String id) async {
    await _client.from('fichas').delete().eq('id', id);
  }

  /// Cambia el estado de la ficha (activo, pausado, cerrado) y opcionalmente guarda una justificación.
  Future<void> cambiarEstadoFicha(String id, String estado, {String? justificacion}) async {
    final Map<String, dynamic> updateData = {'estado': estado};
    if (justificacion != null) {
      updateData['justificacion'] = justificacion;
    } else if (estado == 'activo') {
      // Si se reabre, podríamos limpiar la justificación, o mantenerla.
      // updateData['justificacion'] = null; // opcional
    }

    await _client.from('fichas').update(updateData).eq('id', id);
  }

  /// Cierra la búsqueda cambiando el estado a 'cerrado'.
  Future<void> cerrarFicha(String id, {String? justificacion}) async {
    await cambiarEstadoFicha(id, 'cerrado', justificacion: justificacion);
  }

  /// Pausa la búsqueda cambiando el estado a 'pausado'.
  Future<void> pausarFicha(String id, {String? justificacion}) async {
    await cambiarEstadoFicha(id, 'pausado', justificacion: justificacion);
  }

  /// Reabre una búsqueda cerrada o pausada, volviendo su estado a 'activo'.
  Future<void> reabrirFicha(String id) async {
    // Al reabrir podemos blanquear la justificación si se desea.
    await _client
        .from('fichas')
        .update({'estado': 'activo', 'justificacion': null})
        .eq('id', id);
  }
}
