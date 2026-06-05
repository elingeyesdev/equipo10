import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../models/reporte_model.dart';
import '../services/notification_service.dart';
import '../services/reporte_service.dart';
import '../services/vinculacion_service.dart';

class DetalleFichaViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final VinculacionService _vinculacionService = VinculacionService();

  ReporteModel? _ficha;
  bool _isLoading = false;
  bool _yaVinculado = false;
  int _voluntariosCount = 0;
  String? _errorMessage;
  String? _successMessage;
  List<Map<String, dynamic>> _comentarios = [];

  ReporteModel? get ficha => _ficha;
  bool get isLoading => _isLoading;
  bool get yaVinculado => _yaVinculado;
  int get voluntariosCount => _voluntariosCount;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<Map<String, dynamic>> get comentarios => _comentarios;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Carga la ficha y verifica si el usuario ya está vinculado.
  Future<void> cargarFicha(String fichaId, String usuarioId) async {
    // Limpiar la ficha anterior ANTES de poner isLoading=true.
    // Esto evita que la pantalla de detalle muestre brevemente los datos
    // del reporte anterior mientras carga el nuevo.
    _ficha = null;
    _setLoading(true);
    _errorMessage = null;
    try {
      _ficha = await _reporteService.obtenerReportePorId(fichaId);
      _yaVinculado = await _vinculacionService.estaVinculado(
        fichaId: fichaId,
        usuarioId: usuarioId,
      );
      final voluntarios = await _vinculacionService.obtenerVoluntarios(fichaId);
      _voluntariosCount = voluntarios.length;
      _comentarios = await _reporteService.obtenerComentarios(fichaId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Une el usuario a la búsqueda con metadata opcional del formulario.
  /// Retorna true si fue exitoso.
  /// Tras unirse correctamente, dispara una notificación local de confirmación.
  Future<bool> unirseABusqueda(
    String fichaId,
    String usuarioId, {
    List<String>? habilidadesOfrecidas,
    bool tieneVehiculo = false,
    String? tipoVehiculo,
    String? disponibilidadHoras,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;
    try {
      await _vinculacionService.unirseABusqueda(
        fichaId: fichaId,
        usuarioId: usuarioId,
        habilidadesOfrecidas: habilidadesOfrecidas,
        tieneVehiculo: tieneVehiculo,
        tipoVehiculo: tipoVehiculo,
        disponibilidadHoras: disponibilidadHoras,
      );
      _yaVinculado = true;
      _successMessage = '¡Te has unido a la búsqueda exitosamente!';

      // ── Notificación de confirmación ───────────────────────────────────────
      final nombreOperativo = _ficha?.titulo ?? 'el operativo';
      await NotificationService().show(
        AppNotification(
          type: NotificationType.joinSearchConfirmation,
          title: 'Te uniste a la busqueda',
          body: 'Ahora eres voluntario en "$nombreOperativo". ¡Buena suerte en la misión!',
          payload: {'fichaId': fichaId},
        ),
      );
      // ──────────────────────────────────────────────────────────────────────

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Abandona el operativo: marca al voluntario como inactivo en el backend
  /// y actualiza el estado local para reflejar el cambio en la UI.
  Future<bool> abandonarBusqueda(String fichaId, String usuarioId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _vinculacionService.abandonarBusqueda(
        fichaId: fichaId,
        usuarioId: usuarioId,
      );
      _yaVinculado = false;
      // Decrementar el contador si es mayor a 0
      if (_voluntariosCount > 0) _voluntariosCount--;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Cierra la búsqueda (solo el creador). Actualiza localmente sin navegar.
  Future<bool> cerrarBusqueda(String fichaId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _reporteService.marcarResuelto(fichaId);
      if (_ficha != null) {
        _ficha = _ficha!.copyWith(estado: 'resuelto');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Pausa la búsqueda (solo el creador).
  Future<bool> pausarBusqueda(String fichaId, String justificacion) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _reporteService.pausarReporte(fichaId, justificacion: justificacion);
      if (_ficha != null) {
        _ficha = _ficha!.copyWith(estado: 'pausado');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reabre la búsqueda (solo el creador). 
  Future<bool> reabrirBusqueda(String fichaId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _reporteService.reabrirReporte(fichaId);
      if (_ficha != null) {
        _ficha = _ficha!.copyWith(estado: 'activo');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> enviarComentario(String reporteId, String texto, String usuarioId) async {
    final ok = await _reporteService.enviarComentario(reporteId, texto, usuarioId);
    if (ok) {
      _comentarios = await _reporteService.obtenerComentarios(reporteId);
      notifyListeners();
    } else {
      _errorMessage = 'Error al enviar el comentario.';
      notifyListeners();
    }
  }
}
