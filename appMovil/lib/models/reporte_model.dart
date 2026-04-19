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

  // Getters de compatibilidad para evitar quebrar la UI previamente enlazada a Supabase
  String? get fotoUrl => primeraImagen;
  String get creadoPor => usuarioId;

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
  });

  factory ReporteModel.fromMap(Map<String, dynamic> map) {
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
      primeraImagen: map['primera_imagen']?.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
    };
  }
}
