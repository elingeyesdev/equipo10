class NotificacionModel {
  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final bool leida;
  final DateTime createdAt;
  final Map<String, dynamic>? datosJson;

  NotificacionModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.createdAt,
    this.datosJson,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? '',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      leida: json['leida'] == 1 || json['leida'] == true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      datosJson: json['datos_json'] is Map<String, dynamic>
          ? json['datos_json']
          : null,
    );
  }
}
