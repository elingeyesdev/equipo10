import '../services/api_service.dart';

class ReporteModel {
  final String id;
  final String usuarioId;
  final String? categoriaId;
  final String? cuadranteId;
  final String tipoReporte;
  final String titulo;
  final String descripcion;
  final double? latitud;
  final double? longitud;
  final String estado;
  final String? primeraImagen;
  final String? justificacion;
  // Campos extra del API
  final String? nombreCategoria;
  final String? nombreUsuario;
  final String? telefonoContacto;
  final String? emailContacto;
  final String? direccionReferencia;
  final int? vistas;
  final String? fechaPerdida;
  final String? avatarUsuario;
  final Map<String, dynamic>? caracteristicas;
  final double? recompensa;
  final DateTime? createdAt;
  final int nivelExpansion;

  // Bounds del cuadrante asignado (para geofencing)
  final double? cuadranteLatMin;
  final double? cuadranteLatMax;
  final double? cuadranteLngMin;
  final double? cuadranteLngMax;
  final String? cuadranteNombre;
  final String? cuadranteZona;

  // Getters de compatibilidad para evitar quebrar la UI previamente enlazada a Supabase
  String? get fotoUrl => primeraImagen;
  String get creadoPor => usuarioId;
  dynamic get cuadrantes => expansionesData;

  final List<Map<String, dynamic>>? expansionesData;

  /// Retorna true si [lat, lng] están dentro del cuadrante del reporte.
  bool estaDentroDelCuadrante(double lat, double lng) {
    if (cuadranteLatMin == null ||
        cuadranteLatMax == null ||
        cuadranteLngMin == null ||
        cuadranteLngMax == null) return false;
    return lat >= cuadranteLatMin! &&
        lat <= cuadranteLatMax! &&
        lng >= cuadranteLngMin! &&
        lng <= cuadranteLngMax!;
  }

  ReporteModel({
    required this.id,
    required this.usuarioId,
    this.categoriaId,
    this.cuadranteId,
    required this.tipoReporte,
    required this.titulo,
    required this.descripcion,
    this.latitud,
    this.longitud,
    required this.estado,
    this.primeraImagen,
    this.justificacion,
    this.nombreCategoria,
    this.nombreUsuario,
    this.telefonoContacto,
    this.emailContacto,
    this.direccionReferencia,
    this.vistas,
    this.fechaPerdida,
    this.avatarUsuario,
    this.caracteristicas,
    this.recompensa,
    this.createdAt,
    this.nivelExpansion = 1,
    this.cuadranteLatMin,
    this.cuadranteLatMax,
    this.cuadranteLngMin,
    this.cuadranteLngMax,
    this.cuadranteNombre,
    this.cuadranteZona,
    this.expansionesData,
  });

  factory ReporteModel.fromMap(Map<String, dynamic> map) {
    // Extraer primera imagen de la lista de imágenes si existe
    String? primeraImg = map['primera_imagen']?.toString();
    if (primeraImg != null &&
        (primeraImg.endsWith('/storage') || primeraImg.endsWith('/storage/'))) {
      primeraImg = null;
    }
    if (primeraImg == null || primeraImg.trim().isEmpty) {
      final imgs = map['imagenes'];
      if (imgs is List && imgs.isNotEmpty) {
        primeraImg = imgs[0]['url']?.toString();
      }
    }
    if (primeraImg != null &&
        (primeraImg.endsWith('/storage') || primeraImg.endsWith('/storage/'))) {
      primeraImg = null;
    }

    // Fix para URLs relativas de imágenes (para que se carguen desde el backend)
    if (primeraImg != null && !primeraImg.startsWith('http')) {
      final host = ApiService().apiHost;
      if (primeraImg.startsWith('/')) {
        primeraImg = host + primeraImg;
      } else if (!primeraImg.startsWith('storage/')) {
        primeraImg = '$host/storage/' + primeraImg;
      } else {
        primeraImg = '$host/' + primeraImg;
      }
    } else if (primeraImg != null) {
      // Si el backend devolvió una IP vieja o localhost pero la app está usando otra IP
      final host = ApiService().apiHost;
      // Reemplazamos cualquier IP o localhost en la URL por el host actual del API
      primeraImg = primeraImg.replaceFirst(
          RegExp(r'http://[0-9a-zA-Z\.]+(:[0-9]+)?'), host);
    }
    // Extraer nombre de categoría del objeto anidado
    String? catNombre;
    final cat = map['categoria'];
    if (cat is Map) {
      catNombre = cat['nombre']?.toString();
    }
    // Extraer nombre y avatar del usuario creador
    String? uNombre;
    String? uAvatar;
    final u = map['usuario'];
    if (u is Map) {
      uNombre = u['nombre']?.toString();
      uAvatar = u['avatar_url']?.toString();
    }

    // Fix para URL del avatar del usuario
    if (uAvatar != null && !uAvatar.startsWith('http')) {
      final host = ApiService().apiHost;
      if (uAvatar.startsWith('/')) {
        uAvatar = host + uAvatar;
      } else if (!uAvatar.startsWith('storage/')) {
        uAvatar = '$host/storage/' + uAvatar;
      } else {
        uAvatar = '$host/' + uAvatar;
      }
    } else if (uAvatar != null) {
      final host = ApiService().apiHost;
      // Reemplazamos cualquier IP o localhost en la URL por el host actual del API
      uAvatar = uAvatar.replaceFirst(
          RegExp(r'http://[0-9a-zA-Z\.]+(:[0-9]+)?'), host);
    }

    // Parsear características (backend devuelve lista de objetos [{clave: '...', valor: '...'}])
    Map<String, dynamic>? chars;
    if (map['caracteristicas'] is List) {
      chars = {};
      for (final item in map['caracteristicas']) {
        if (item is Map && item['clave'] != null) {
          chars[item['clave']] = item['valor'];
        }
      }
      if (chars.isEmpty) chars = null;
    }

    List<Map<String, dynamic>>? expansionesList;
    if (map['expansiones'] is List) {
      expansionesList = List<Map<String, dynamic>>.from(map['expansiones']);
    }

    return ReporteModel(
      id: map['id']?.toString() ?? '',
      usuarioId: map['usuario_id']?.toString() ?? '',
      categoriaId: map['categoria_id']?.toString(),
      cuadranteId: map['cuadrante_id']?.toString(),
      tipoReporte: map['tipo_reporte']?.toString() ?? 'objeto',
      titulo: map['titulo']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      latitud: _parseDouble(map['ubicacion_exacta_lat']),
      longitud: _parseDouble(map['ubicacion_exacta_lng']),
      estado: map['estado']?.toString() ?? 'activo',
      primeraImagen: primeraImg,
      justificacion: map['justificacion']?.toString(),
      nombreCategoria: catNombre,
      nombreUsuario: uNombre,
      telefonoContacto: map['telefono_contacto']?.toString(),
      emailContacto: map['email_contacto']?.toString(),
      direccionReferencia: map['direccion_referencia']?.toString(),
      vistas: map['vistas'] is int
          ? map['vistas']
          : int.tryParse(map['vistas']?.toString() ?? ''),
      fechaPerdida: map['fecha_perdida']?.toString(),
      avatarUsuario: uAvatar,
      caracteristicas: chars,
      recompensa: _parseDouble(map['recompensa']),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      nivelExpansion:
          int.tryParse(map['nivel_expansion']?.toString() ?? '1') ?? 1,
      cuadranteLatMin: _parseDouble(map['cuadrante']?['lat_min']),
      cuadranteLatMax: _parseDouble(map['cuadrante']?['lat_max']),
      cuadranteLngMin: _parseDouble(map['cuadrante']?['lng_min']),
      cuadranteLngMax: _parseDouble(map['cuadrante']?['lng_max']),
      cuadranteNombre: map['cuadrante']?['nombre']?.toString(),
      cuadranteZona: map['cuadrante']?['zona']?.toString(),
      expansionesData: expansionesList,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  ReporteModel copyWith({
    String? id,
    String? usuarioId,
    String? categoriaId,
    String? cuadranteId,
    String? tipoReporte,
    String? titulo,
    String? descripcion,
    double? latitud,
    double? longitud,
    String? estado,
    String? primeraImagen,
    String? justificacion,
    String? nombreCategoria,
    String? nombreUsuario,
    String? telefonoContacto,
    String? emailContacto,
    String? direccionReferencia,
    int? vistas,
    String? fechaPerdida,
    Map<String, dynamic>? caracteristicas,
    double? recompensa,
    int? nivelExpansion,
  }) {
    return ReporteModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      categoriaId: categoriaId ?? this.categoriaId,
      cuadranteId: cuadranteId ?? this.cuadranteId,
      tipoReporte: tipoReporte ?? this.tipoReporte,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      estado: estado ?? this.estado,
      primeraImagen: primeraImagen ?? this.primeraImagen,
      justificacion: justificacion ?? this.justificacion,
      nombreCategoria: nombreCategoria ?? this.nombreCategoria,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      telefonoContacto: telefonoContacto ?? this.telefonoContacto,
      emailContacto: emailContacto ?? this.emailContacto,
      direccionReferencia: direccionReferencia ?? this.direccionReferencia,
      vistas: vistas ?? this.vistas,
      fechaPerdida: fechaPerdida ?? this.fechaPerdida,
      caracteristicas: caracteristicas ?? this.caracteristicas,
      recompensa: recompensa ?? this.recompensa,
      nivelExpansion: nivelExpansion ?? this.nivelExpansion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'categoria_id': categoriaId,
      'cuadrante_id': cuadranteId,
      'tipo_reporte': tipoReporte,
      'titulo': titulo,
      'descripcion': descripcion,
      'ubicacion_exacta_lat': latitud,
      'ubicacion_exacta_lng': longitud,
      'estado': estado,
      'justificacion': justificacion,
    };
  }
}
