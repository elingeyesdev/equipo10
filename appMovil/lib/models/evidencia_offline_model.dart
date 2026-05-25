import 'dart:convert';

/// Representa una evidencia fotográfica que no pudo ser subida por
/// falta de conexión a red y quedó encolada localmente.
class EvidenciaOfflineModel {
  final String id; // UUID o timestamp único
  final String reporteId;
  final String usuarioId;
  final String descripcion;
  final double? lat;
  final double? lng;
  final String imagePath; // Ruta local del archivo
  final DateTime creadoEn;

  EvidenciaOfflineModel({
    required this.id,
    required this.reporteId,
    required this.usuarioId,
    required this.descripcion,
    this.lat,
    this.lng,
    required this.imagePath,
    required this.creadoEn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporteId': reporteId,
      'usuarioId': usuarioId,
      'descripcion': descripcion,
      'lat': lat,
      'lng': lng,
      'imagePath': imagePath,
      'creadoEn': creadoEn.toIso8601String(),
    };
  }

  factory EvidenciaOfflineModel.fromMap(Map<String, dynamic> map) {
    return EvidenciaOfflineModel(
      id: map['id'],
      reporteId: map['reporteId'],
      usuarioId: map['usuarioId'],
      descripcion: map['descripcion'],
      lat: map['lat'],
      lng: map['lng'],
      imagePath: map['imagePath'],
      creadoEn: DateTime.parse(map['creadoEn']),
    );
  }

  String toJson() => json.encode(toMap());

  factory EvidenciaOfflineModel.fromJson(String source) =>
      EvidenciaOfflineModel.fromMap(json.decode(source));
}
