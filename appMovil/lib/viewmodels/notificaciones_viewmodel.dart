import 'package:flutter/material.dart';
import '../models/notificacion_model.dart';
import '../services/notificacion_api_service.dart';
import '../services/auth_service.dart';

class NotificacionesViewModel extends ChangeNotifier {
  final NotificacionApiService _apiService = NotificacionApiService();
  final AuthService _authService = AuthService();

  List<NotificacionModel> _notificaciones = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificacionModel> get notificaciones => _notificaciones;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notificaciones.where((n) => !n.leida).length;

  Future<void> cargarNotificaciones() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notificaciones = await _apiService.obtenerNotificacionesUsuario(userId);
      // Ordenar por fecha descendente
      _notificaciones.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marcarTodasComoLeidas() async {
    final noLeidas = _notificaciones.where((n) => !n.leida).toList();
    if (noLeidas.isEmpty) return;

    // Optimistic update
    _notificaciones = _notificaciones.map((n) => n.leida
        ? n
        : NotificacionModel(
            id: n.id,
            tipo: n.tipo,
            titulo: n.titulo,
            mensaje: n.mensaje,
            leida: true,
            createdAt: n.createdAt,
            datosJson: n.datosJson,
          )).toList();
    notifyListeners();

    await _apiService.marcarTodasComoLeidas(noLeidas.map((n) => n.id).toList());
  }

  Future<void> marcarComoLeida(String notificacionId) async {
    final index = _notificaciones.indexWhere((n) => n.id == notificacionId);
    if (index == -1 || _notificaciones[index].leida) return;

    // Optimistic update
    final notifOriginal = _notificaciones[index];
    _notificaciones[index] = NotificacionModel(
      id: notifOriginal.id,
      tipo: notifOriginal.tipo,
      titulo: notifOriginal.titulo,
      mensaje: notifOriginal.mensaje,
      leida: true,
      createdAt: notifOriginal.createdAt,
      datosJson: notifOriginal.datosJson,
    );
    notifyListeners();

    final success = await _apiService.marcarComoLeida(notificacionId);
    if (!success) {
      // Revert if failed
      _notificaciones[index] = notifOriginal;
      notifyListeners();
    }
  }
}
