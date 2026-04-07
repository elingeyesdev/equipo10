import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ficha_model.dart';

class FichaService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();
  static const String _bucket = 'fotos_fichas';

  /// Obtiene todas las fichas activas y cerradas (excluye eliminadas).
  Future<List<FichaModel>> obtenerFichas() async {
    final data = await _client
        .from('fichas')
        .select()
        .inFilter('estado', ['activo', 'cerrado'])
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
  }) async {
    await _client.from('fichas').insert({
      'id': _uuid.v4(),
      'creado_por': creadoPor,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
      'latitud': latitud,
      'longitud': longitud,
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

  /// Elimina una ficha por ID.
  Future<void> eliminarFicha(String id) async {
    await _client.from('fichas').delete().eq('id', id);
  }

  /// Cierra la búsqueda cambiando el estado a 'cerrado'.
  Future<void> cerrarFicha(String id) async {
    await _client
        .from('fichas')
        .update({'estado': 'cerrado'})
        .eq('id', id);
  }

  /// Reabre una búsqueda cerrada, volviendo su estado a 'activo'.
  Future<void> reabrirFicha(String id) async {
    await _client
        .from('fichas')
        .update({'estado': 'activo'})
        .eq('id', id);
  }
}
