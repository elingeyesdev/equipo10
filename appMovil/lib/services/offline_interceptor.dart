import 'package:dio/dio.dart';
import 'connectivity_service.dart';

/// Excepción específica lanzada cuando una petición falla porque el dispositivo
/// no tiene conectividad de red detectada por [ConnectivityService].
///
/// Permite que las capas superiores (ViewModels, UI) distingan entre un error
/// de servidor (DioException) y un error de red por ausencia de conexión.
class OfflineException implements Exception {
  final String message;
  const OfflineException([this.message = 'Sin conexión a internet.']);

  @override
  String toString() => 'OfflineException: $message';
}

/// Interceptor de Dio que comprueba el estado de conectividad ANTES de lanzar
/// cada petición HTTP.
///
/// Si [ConnectivityService.isOnline] es `false`, cancela la petición
/// inmediatamente lanzando [OfflineException] para evitar timeouts largos y
/// proporcionar feedback instantáneo al usuario.
///
/// E9.1 — Módulo Offline: Interceptor de red en Dio con activación del modo
/// offline cuando no hay conectividad detectada.
class OfflineInterceptor extends Interceptor {
  final ConnectivityService _connectivity;

  OfflineInterceptor(this._connectivity);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_connectivity.isOnline) {
      // Rechazamos la petición de forma controlada; no ejecutamos handler.next
      handler.reject(
        DioException(
          requestOptions: options,
          error: const OfflineException(),
          type: DioExceptionType.connectionError,
          message: 'Sin conexión a internet.',
        ),
        true, // callFollowingErrorInterceptor = true → pasa por onError
      );
      return;
    }
    handler.next(options);
  }
}
