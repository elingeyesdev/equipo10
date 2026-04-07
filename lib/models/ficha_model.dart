class FichaModel {
  final String id;
  final String creadoPor;
  final String titulo;
  final String descripcion;
  final String? fotoUrl;
  final double? latitud;
  final double? longitud;
  final String estado;

  FichaModel({
    required this.id,
    required this.creadoPor,
    required this.titulo,
    required this.descripcion,
    this.fotoUrl,
    this.latitud,
    this.longitud,
    this.estado = 'activo',
  });

  factory FichaModel.fromMap(Map<String, dynamic> map) {
    return FichaModel(
      id: map['id'] as String,
      creadoPor: map['creado_por'] as String,
      titulo: map['titulo'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      fotoUrl: map['foto_url'] as String?,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      estado: map['estado'] as String? ?? 'activo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creado_por': creadoPor,
      'titulo': titulo,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
    };
  }
}
