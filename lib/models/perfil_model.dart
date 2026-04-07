class PerfilModel {
  final String id;
  final String nombreCompleto;
  final String telefono;

  PerfilModel({
    required this.id,
    required this.nombreCompleto,
    required this.telefono,
  });

  factory PerfilModel.fromMap(Map<String, dynamic> map) {
    return PerfilModel(
      id: map['id'] as String,
      nombreCompleto: map['nombre_completo'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'telefono': telefono,
    };
  }
}
