import '../services/api_service.dart';

/// Representa una evidencia fotográfica capturada por un voluntario.
/// Internamente es una Respuesta de tipo 'avistamiento' con imagen y GPS.
class EvidenciaModel {
  final String id;
  final String reporteId;
  final String usuarioId;
  final String? nombreUsuario;
  final String? avatarUsuario;
  final String descripcion;
  final double? lat;
  final double? lng;
  final String? fotoUrl;
  final DateTime? creadoEn;
  // Estado de aprobacion: pending, approved, rejected
  final String estado;
  final bool esClave;

  EvidenciaModel({
    required this.id,
    required this.reporteId,
    required this.usuarioId,
    this.nombreUsuario,
    this.avatarUsuario,
    required this.descripcion,
    this.lat,
    this.lng,
    this.fotoUrl,
    this.creadoEn,
    this.estado = 'approved',
    this.esClave = false,
  });

  factory EvidenciaModel.fromMap(Map<String, dynamic> map) {
    // Extraer URL de la primera imagen si existe
    String? imgUrl;
    final imgs = map['imagenes'];
    if (imgs is List && imgs.isNotEmpty) {
      imgUrl = imgs[0]['url']?.toString();
    }

    // Normalizar URL (igual que en ReporteModel)
    if (imgUrl != null && !imgUrl.startsWith('http')) {
      final host = ApiService().apiHost;
      imgUrl = imgUrl.startsWith('/') ? host + imgUrl : '$host/storage/$imgUrl';
    } else if (imgUrl != null) {
      final host = ApiService().apiHost;
      imgUrl =
          imgUrl.replaceFirst(RegExp(r'https?://[^/]+'), host);
    }

    // Extraer datos del usuario
    String? uNombre;
    String? uAvatar;
    final u = map['usuario'];
    if (u is Map) {
      uNombre = u['nombre']?.toString();
      uAvatar = u['avatar_url']?.toString();
      if (uAvatar != null && !uAvatar.startsWith('http')) {
        final host = ApiService().apiHost;
        uAvatar =
            uAvatar.startsWith('/') ? host + uAvatar : '$host/storage/$uAvatar';
      } else if (uAvatar != null) {
        final host = ApiService().apiHost;
        uAvatar = uAvatar.replaceFirst(
            RegExp(r'https?://[^/]+'), host);
      }
    }

    return EvidenciaModel(
      id: map['id']?.toString() ?? '',
      reporteId: map['reporte_id']?.toString() ?? '',
      usuarioId: map['usuario_id']?.toString() ?? '',
      nombreUsuario: uNombre,
      avatarUsuario: uAvatar,
      descripcion: map['mensaje']?.toString() ?? '',
      lat: _parseDouble(map['ubicacion_lat']),
      lng: _parseDouble(map['ubicacion_lng']),
      fotoUrl: imgUrl,
      creadoEn: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      estado: map['estado_evidencia']?.toString() ?? 'pending',
      esClave: map['es_clave'] == true || map['es_clave'] == 1,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
