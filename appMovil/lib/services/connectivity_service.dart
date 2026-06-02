import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton centralizado para el estado de conectividad de red.
///
/// Expone:
///   - [isOnline]       : estado actual (sincrónico).
///   - [statusStream]   : Stream que emite cada cambio de estado.
///
/// E9.1 — Módulo Offline: Detección de conectividad con activación automática
/// del modo offline en toda la aplicación.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;

  /// `true` si el dispositivo tiene al menos una conexión de red activa.
  bool get isOnline => _isOnline;

  /// Stream que emite `true` cuando hay red y `false` cuando no la hay.
  /// Internamente filtra los eventos repetidos para no generar notificaciones
  /// innecesarias a los listeners.
  Stream<bool> get statusStream => _controller.stream;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    // 1. Leer el estado actual al arrancar
    final results = await _connectivity.checkConnectivity();
    _update(results);

    // 2. Escuchar cambios en tiempo real
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(_isOnline);
      notifyListeners();
      debugPrint(
        '[ConnectivityService] Estado de red: ${_isOnline ? "🟢 EN LÍNEA" : "🔴 SIN CONEXIÓN"}',
      );
    }
  }

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }
}
