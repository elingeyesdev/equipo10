import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/reporte_model.dart';

class ReporteService {
  final ApiService _api = ApiService();

  Future<List<ReporteModel>> obtenerReportes({
    String? tipoReporte,
    String? estado,
    double? lat,
    double? lng,
    double? radio,
  }) async {
    final params = <String, dynamic>{};
    if (tipoReporte != null && tipoReporte.isNotEmpty) params['tipo_reporte'] = tipoReporte;
    if (estado != null && estado.isNotEmpty) params['estado'] = estado;
    if (lat != null && lng != null && radio != null) {
      params['lat'] = lat;
      params['lng'] = lng;
      params['radio'] = radio;
    }

    final response = await _api.client.get('/reportes', queryParameters: params);
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

  /// Obtiene la galería centralizada del reporte
  Future<List<Map<String, dynamic>>> obtenerGaleria(String reporteId) async {
    try {
      final response = await _api.client.get('/reportes/$reporteId/galeria');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtiene los comentarios públicos de un reporte
  Future<List<Map<String, dynamic>>> obtenerComentarios(String reporteId) async {
    try {
      final response = await _api.client.get('/reportes/$reporteId/comentarios');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Envía un comentario público a un reporte
  Future<bool> enviarComentario(String reporteId, String texto, String usuarioId) async {
    try {
      final response = await _api.client.post('/reportes/$reporteId/comentarios', data: {
        'texto': texto,
        'usuario_id': usuarioId,
      });
      return response.statusCode == 201 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Marca temporalmente el reporte como Oculto/Cerrado (Resuelto)
  Future<void> marcarResuelto(String reporteId, {String? justificacion}) async {
    final Map<String, dynamic> data = {
      'justificacion': (justificacion != null && justificacion.isNotEmpty) ? justificacion : null,
    };
    
    final response = await _api.client.put(
      '/reportes/$reporteId/resuelto',
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Fallo al cerrar o resolver el reporte.');
    }
  }

  /// Pausa el reporte, opcionalmente recibiendo una justificación
  Future<void> pausarReporte(String reporteId, {String? justificacion}) async {
    final Map<String, dynamic> data = {
      'justificacion': (justificacion != null && justificacion.isNotEmpty) ? justificacion : null,
    };
    
    try {
      final response = await _api.client.put(
        '/reportes/$reporteId/pausar',
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode != 200) {
        throw Exception('Fallo al pausar el reporte.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.response?.data?['message'] ?? e.message;
      throw Exception(msg);
    }
  }

  /// Reabre un reporte marcándolo como Activo
  Future<void> reabrirReporte(String reporteId) async {
    final response = await _api.client.put('/reportes/$reporteId/reabrir');
    if (response.statusCode != 200) {
      throw Exception('Fallo al reabrir el reporte.');
    }
  }

  /// Sube una imagen usando MultipartFile y devuelve la URL pública.
  Future<String> subirImagen(dynamic xFile) async {
    final bytes = await xFile.readAsBytes();
    final fileName = xFile.name;
    final String ext = fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';

    final formData = FormData.fromMap({
      'imagen': MultipartFile.fromBytes(
        bytes, 
        filename: fileName,
        contentType: DioMediaType('image', ext),
      ),
    });

    // Dio tomará automáticamente el FormData y le pondrá el multipart/form-data y boundary correctos
    final response = await _api.client.post(
      '/reportes/upload-image', 
      data: formData,
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['url'];
    }
    throw Exception('Error al subir la imagen');
  }

  /// Crea un nuevo reporte
  Future<ReporteModel> crearReporte({
    required String usuarioId,
    required String categoriaId,
    required String titulo,
    required String descripcion,
    required double latitud,
    required double longitud,
    String? cuadranteId,
    String? fotoUrl,
    String? fechaPerdida,
    String? direccionReferencia,
    String? telefonoContacto,
    double? recompensa,
    Map<String, dynamic>? caracteristicasExtra,
  }) async {
    final Map<String, dynamic> data = {
      'usuario_id': usuarioId,
      'categoria_id': categoriaId,
      'cuadrante_id': cuadranteId,
      'tipo_reporte': 'perdido',
      'titulo': titulo,
      'descripcion': descripcion,
      'ubicacion_exacta_lat': latitud,
      'ubicacion_exacta_lng': longitud,
      'contacto_publico': true,
    };

    if (fotoUrl != null) data['imagenes'] = [fotoUrl];
    if (fechaPerdida != null) data['fecha_perdida'] = fechaPerdida;
    if (direccionReferencia != null) data['direccion_referencia'] = direccionReferencia;
    if (telefonoContacto != null) data['telefono_contacto'] = telefonoContacto;
    if (recompensa != null) data['recompensa'] = recompensa;
    if (caracteristicasExtra != null && caracteristicasExtra.isNotEmpty) {
      data['caracteristicas'] = caracteristicasExtra;
    }

    try {
      final response = await _api.client.post('/reportes', data: data);
      if (response.statusCode == 201 && response.data['success'] == true) {
        return ReporteModel.fromMap(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Error al crear el reporte');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;

      if (statusCode == 422) {
        // Extraer primer error de validación del servidor
        final errors = body?['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstMsg = (errors.values.first as List?)?.first?.toString();
          throw Exception(firstMsg ?? 'Datos inválidos. Revisa los campos del formulario.');
        }
        throw Exception('Datos inválidos. Revisa los campos del formulario.');
      }

      if (statusCode == 500) {
        throw Exception('API ERROR: ${body?['error'] ?? body?['message'] ?? 'Error desconocido del servidor'}');
      }

      throw Exception(body?['message'] ?? 'Error de conexión. Intenta de nuevo.');
    }
  }

  /// Edita un reporte
  Future<void> editarFicha({
    required String id,
    required String titulo,
    required String descripcion,
    String? fotoUrl,
    String? telefonoContacto,
    double? recompensa,
    String? direccionReferencia,
    String? fechaPerdida,
    Map<String, dynamic>? caracteristicasExtra,
  }) async {
    final Map<String, dynamic> data = {
      'titulo': titulo,
      'descripcion': descripcion,
    };

    if (telefonoContacto != null) data['telefono_contacto'] = telefonoContacto;
    if (recompensa != null) data['recompensa'] = recompensa;
    if (direccionReferencia != null) data['direccion_referencia'] = direccionReferencia;
    if (fechaPerdida != null) data['fecha_perdida'] = fechaPerdida;
    if (caracteristicasExtra != null) data['caracteristicas'] = caracteristicasExtra;

    // Solo incluir 'imagenes' si hay una URL válida.
    // Enviar una lista vacía hace que el backend intente borrar todas las
    // imágenes y lanza un 500. Si el usuario no cambió ni borró la imagen,
    // simplemente no mandamos el campo y el servidor no toca las imágenes.
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      data['imagenes'] = [fotoUrl];
    }

    try {
      final response = await _api.client.put('/reportes/$id', data: data);
      if (response.statusCode != 200) {
        throw Exception('Fallo al actualizar el reporte.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Error al actualizar el reporte.';
      throw Exception(msg);
    }
  }

  /// Elimina un reporte
  Future<void> eliminarFicha(String id) async {
    final response = await _api.client.delete('/reportes/$id');
    if (response.statusCode != 200) {
      throw Exception('Fallo al eliminar el reporte.');
    }
  }

  /// Obtiene los recorridos de los voluntarios para un reporte
  Future<List<dynamic>> obtenerRecorridos(String reporteId) async {
    final response = await _api.client.get('/reportes/$reporteId/voluntarios/recorridos');
    if (response.statusCode == 200) {
      final body = response.data;
      if (body['success'] == true) {
        return body['data'] as List<dynamic>;
      }
    }
    throw Exception('No se pudieron obtener los recorridos.');
  }

  /// Obtiene las pistas asociadas a un reporte
  Future<List<dynamic>> obtenerPistas(String reporteId) async {
    final response = await _api.client.get('/reportes/$reporteId/pistas');
    if (response.statusCode == 200) {
      final body = response.data;
      if (body['success'] == true) {
        return body['data'] as List<dynamic>;
      }
    }
    return [];
  }

  /// Envía un mensaje masivo (broadcast) a los voluntarios activos
  Future<bool> enviarAlertaMasiva(String reporteId, String mensaje) async {
    try {
      final response = await _api.client.post('/reportes/$reporteId/broadcast', data: {
        'mensaje': mensaje,
      });
      if (response.statusCode == 200) {
        final body = response.data;
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Envía un mensaje directo a un voluntario específico
  Future<bool> enviarMensajeDirecto(String reporteId, String usuarioId, String mensaje) async {
    try {
      final response = await _api.client.post('/reportes/$reporteId/mensaje/$usuarioId', data: {
        'mensaje': mensaje,
      });
      if (response.statusCode == 200) {
        final body = response.data;
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los datos consolidados del operativo para el reporte final PDF.
  ///
  /// Llama al endpoint `GET /reportes/{id}/reporte-final` implementado en E13.2.
  /// Retorna un [Map] con: ficha, estadísticas, evidencias y datos de voluntarios.
  Future<Map<String, dynamic>> obtenerDatosReporteFinal(String reporteId) async {
    final response = await _api.client.get('/reportes/$reporteId/reporte-final');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    throw Exception('No se pudieron obtener los datos del reporte final.');
  }
}
