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
  final String? prioridad;
  final int? vistas;
  final String? fechaPerdida;

  // Getters de compatibilidad para evitar quebrar la UI previamente enlazada a Supabase
  String? get fotoUrl => primeraImagen;
  String get creadoPor => usuarioId;
  dynamic get cuadrantes => null;

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
    this.prioridad,
    this.vistas,
    this.fechaPerdida,
  });

  factory ReporteModel.fromMap(Map<String, dynamic> map) {
    // Extraer primera imagen de la lista de imágenes si existe
    String? primeraImg = map['primera_imagen']?.toString();
    if (primeraImg == null) {
      final imgs = map['imagenes'];
      if (imgs is List && imgs.isNotEmpty) {
        primeraImg = imgs[0]['url']?.toString();
      }
    }
    // Extraer nombre de categoría del objeto anidado
    String? catNombre;
    final cat = map['categoria'];
    if (cat is Map) {
      catNombre = cat['nombre']?.toString();
    }
    // Extraer nombre del usuario creador
    String? uNombre;
    final u = map['usuario'];
    if (u is Map) {
      uNombre = u['nombre']?.toString();
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
      prioridad: map['prioridad']?.toString(),
      vistas: map['vistas'] is int ? map['vistas'] : int.tryParse(map['vistas']?.toString() ?? ''),
      fechaPerdida: map['fecha_perdida']?.toString(),
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
    String? prioridad,
    int? vistas,
    String? fechaPerdida,
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
      prioridad: prioridad ?? this.prioridad,
      vistas: vistas ?? this.vistas,
      fechaPerdida: fechaPerdida ?? this.fechaPerdida,
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
