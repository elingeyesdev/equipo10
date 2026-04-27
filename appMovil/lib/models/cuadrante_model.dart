import 'dart:convert';

class CuadranteModel {
  final String id;
  final String codigo;
  final String nombre;
  final String? zona;
  final String? ciudad;
  final Map<String, dynamic>? geometria;
  final double centroLat;
  final double centroLng;

  CuadranteModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.zona,
    this.ciudad,
    this.geometria,
    required this.centroLat,
    required this.centroLng,
  });

  factory CuadranteModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? geo;
    if (map['geometria'] != null) {
      if (map['geometria'] is String) {
        geo = jsonDecode(map['geometria']);
      } else {
        geo = map['geometria'];
      }
    }

    return CuadranteModel(
      id: map['id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      zona: map['zona']?.toString(),
      ciudad: map['ciudad']?.toString(),
      geometria: geo,
      centroLat: double.tryParse(map['centro_lat']?.toString() ?? '0') ?? 0,
      centroLng: double.tryParse(map['centro_lng']?.toString() ?? '0') ?? 0,
    );
  }
}
