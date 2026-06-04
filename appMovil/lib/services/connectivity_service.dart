import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton centralizado para el estado de conectividad y calidad de red.
///
/// Expone:
///   - [isOnline]        : si hay conexión de red (sin importar calidad).
///   - [isHighLatency]   : true cuando la latencia supera [latencyThresholdMs].
///   - [latencyMs]       : última medición de latencia en milisegundos.
///   - [shouldUseCache]  : true si se deben servir datos del caché local.
///   - [statusStream]    : Stream de cambios de conectividad (online/offline).
///   - [latencyStream]   : Stream que emite latencia medida en cada sondeo.
///
/// E9.1 — Módulo Offline: Detección de conectividad.
/// E9.4 — Módulo Offline: Recuperación desde caché cuando la latencia es alta.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _init();
  }

  // ── Configuración ─────────────────────────────────────────────────────────

  /// Latencia en ms por encima de la cual se considera conexión "lenta".
  static const int latencyThresholdMs = 1500;

  /// Intervalo entre sondeos de latencia (cuando hay conexión).
  static const Duration _sondeoInterval = Duration(seconds: 20);

  /// Timeout para el sondeo de latencia.
  static const Duration _sondeoTimeout = Duration(seconds: 4);

  /// Host que se sondea para medir latencia (el propio backend de la app).
  static const String _sondeoHost = '192.168.0.215';
  static const int _sondeoPort = 8081;

  // ── Estado interno ────────────────────────────────────────────────────────

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _latencyTimer;

  bool _isOnline = true;
  int _latencyMs = 0;
  bool _isHighLatency = false;

  // ── Streams ───────────────────────────────────────────────────────────────

  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();
  final StreamController<int> _latencyController =
      StreamController<int>.broadcast();

  /// `true` si hay al menos una interfaz de red activa.
  bool get isOnline => _isOnline;

  /// Última latencia medida en ms (0 si no se ha medido aún).
  int get latencyMs => _latencyMs;

  /// `true` si la latencia supera [latencyThresholdMs].
  bool get isHighLatency => _isHighLatency;

  /// `true` cuando los servicios deben servir datos del caché local:
  /// sin conexión O con conexión pero latencia alta.
  bool get shouldUseCache => !_isOnline || _isHighLatency;

  /// Stream de cambios de estado de red (`true` = online, `false` = offline).
  Stream<bool> get statusStream => _statusController.stream;

  /// Stream que emite la latencia (ms) después de cada sondeo.
  Stream<int> get latencyStream => _latencyController.stream;

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> _init() async {
    // 1. Estado inicial de conectividad
    final results = await _connectivity.checkConnectivity();
    _updateConnectivity(results);

    // 2. Escuchar cambios de interfaz de red
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectivity);

    // 3. Sondeo periódico de latencia (solo cuando hay red)
    _latencyTimer = Timer.periodic(_sondeoInterval, (_) {
      if (_isOnline) _medirLatencia();
    });

    // 4. Primera medición inmediata
    if (_isOnline) _medirLatencia();
  }

  // ── Conectividad ──────────────────────────────────────────────────────────

  void _updateConnectivity(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      _statusController.add(_isOnline);
      notifyListeners();
      debugPrint(
        '[ConnectivityService] Red: ${_isOnline ? "🟢 EN LÍNEA" : "🔴 SIN CONEXIÓN"}',
      );

      if (_isOnline) {
        // Al recuperar red, medir latencia de inmediato
        _medirLatencia();
      } else {
        // Sin red: resetear latencia
        _setLatency(0, highLatency: false);
      }
    }
  }

  // ── Medición de latencia ──────────────────────────────────────────────────

  /// Mide la latencia realizando una conexión TCP al host del backend.
  /// TCP es más ligero que HTTP: no necesita parsear respuesta.
  Future<void> _medirLatencia() async {
    if (!_isOnline) return;

    final stopwatch = Stopwatch()..start();
    bool reached = false;

    try {
      final socket = await Socket.connect(
        _sondeoHost,
        _sondeoPort,
        timeout: _sondeoTimeout,
      );
      stopwatch.stop();
      socket.destroy();
      reached = true;
    } catch (_) {
      stopwatch.stop();
    }

    final ms = stopwatch.elapsedMilliseconds;

    if (reached) {
      final wasHigh = _isHighLatency;
      _setLatency(ms, highLatency: ms >= latencyThresholdMs);

      if (_isHighLatency != wasHigh) {
        debugPrint(
          '[ConnectivityService] Latencia: ${ms}ms — '
          '${_isHighLatency ? "🟡 ALTA" : "🟢 NORMAL"}',
        );
        notifyListeners();
      } else {
        debugPrint('[ConnectivityService] Latencia: ${ms}ms');
      }
    } else {
      // No se pudo alcanzar el servidor → tratar como latencia muy alta
      _setLatency(latencyThresholdMs + 1, highLatency: true);
      debugPrint(
          '[ConnectivityService] Latencia: ∞ (no se pudo conectar al servidor)');
      notifyListeners();
    }
  }

  /// Fuerza una medición inmediata de latencia (útil antes de una petición).
  Future<void> medirAhora() => _medirLatencia();

  void _setLatency(int ms, {required bool highLatency}) {
    _latencyMs = ms;
    _isHighLatency = highLatency;
    _latencyController.add(ms);
  }

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _latencyTimer?.cancel();
    _statusController.close();
    _latencyController.close();
    super.dispose();
  }
}
