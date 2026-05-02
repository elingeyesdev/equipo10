import '../services/api_service.dart';

class PerfilModel {
  final String id;
  final String nombreCompleto;
  final String telefono;
  final String email;
  final String? avatarUrl;
  final List<String> habilidades;
  final Map<String, dynamic> estadisticas;

  PerfilModel({
    required this.id,
    required this.nombreCompleto,
    required this.telefono,
    this.email = '',
    this.avatarUrl,
    this.habilidades = const [],
    this.estadisticas = const {},
  });

  factory PerfilModel.fromMap(Map<String, dynamic> map) {
    return PerfilModel(
      id: map['id'] as String,
      nombreCompleto: map['nombre_completo'] as String? ?? map['nombre'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: _parseAvatarUrl(map['avatar_url'] as String?),
      habilidades: map['habilidades'] != null ? List<String>.from(map['habilidades']) : [],
      estadisticas: map['estadisticas'] != null ? Map<String, dynamic>.from(map['estadisticas']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'telefono': telefono,
      'email': email,
      'avatar_url': avatarUrl,
      'habilidades': habilidades,
      'estadisticas': estadisticas,
    };
  }
  static String? _parseAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiService().apiHost}/storage/$path';
  }
}
