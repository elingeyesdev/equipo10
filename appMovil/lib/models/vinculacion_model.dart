class VinculacionModel {
  final String id;
  final String fichaId;
  final String usuarioId;

  VinculacionModel({
    required this.id,
    required this.fichaId,
    required this.usuarioId,
  });

  factory VinculacionModel.fromMap(Map<String, dynamic> map) {
    return VinculacionModel(
      id: map['id'] as String,
      fichaId: map['ficha_id'] as String,
      usuarioId: map['usuario_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ficha_id': fichaId,
      'usuario_id': usuarioId,
    };
  }
}
