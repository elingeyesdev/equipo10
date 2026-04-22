class CategoriaModel {
  final String id;
  final String nombre;
  final String? icono;
  final String? color;
  final String? descripcion;

  CategoriaModel({
    required this.id,
    required this.nombre,
    this.icono,
    this.color,
    this.descripcion,
  });

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      icono: map['icono'],
      color: map['color'],
      descripcion: map['descripcion'],
    );
  }
}
