import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importando tu servicio
import 'package:echoes/services/tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configuramos los Mocks nativos una sola vez para toda la suite de pruebas
  setUpAll(() {
    // Mockeamos SharedPreferences porque el ApiService lo usa internamente
    SharedPreferences.setMockInitialValues({});

    // 1. Mock Conectividad (requerido indirectamente por el ApiService)
    const MethodChannel connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      connectivityChannel,
      (MethodCall methodCall) async => ['wifi'],
    );

    // 2. Mock Geolocator (requerido por TrackingService para solicitar permisos)
    const MethodChannel geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      geolocatorChannel,
      (MethodCall methodCall) async {
        // Simulamos que el usuario otorgó los permisos de GPS (valor 3 = LocationPermission.always)
        if (methodCall.method == 'checkPermission' || methodCall.method == 'requestPermission') {
          return 3; 
        }
        return null;
      },
    );
  });

  group('Suite de Pruebas Rigurosas - TrackingService (Entregable 6)', () {
    late TrackingService trackingService;

    // Se ejecuta ANTES de CADA test, garantizando que el entorno esté limpio
    setUp(() {
      trackingService = TrackingService();
      trackingService.reset();
    });

    test('1. Estado Inicial: El servicio debe iniciar limpio y detenido', () {
      expect(trackingService.isTracking, false, reason: 'El servicio no debe estar activo por defecto.');
      expect(trackingService.isPaused, false, reason: 'El servicio no debe estar pausado por defecto.');
      expect(trackingService.totalPuntos, 0, reason: 'La lista de puntos debe estar vacía inicialmente.');
      expect(trackingService.puntos.isEmpty, true);
    });

    test('2. Inicio de Tracking: Cambia el estado a activo al obtener permisos de GPS', () async {
      // Act
      final exito = await trackingService.iniciarTracking(reporteId: 'rep_001', usuarioId: 'usr_001');
      
      // Assert
      expect(exito, true, reason: 'El tracking debió iniciar exitosamente ya que simulamos que hay permisos.');
      expect(trackingService.isTracking, true, reason: 'La variable de estado principal (_isTracking) debe ser verdadera.');
      expect(trackingService.isPaused, false, reason: 'Al iniciar, no debe arrancar en pausa.');
    });

    test('3. Máquina de Estados (Pausa y Reanudación): Actualización estricta de banderas', () async {
      // Arrange - Arrancamos el tracking
      await trackingService.iniciarTracking(reporteId: 'rep_001', usuarioId: 'usr_001');
      expect(trackingService.isTracking, true);

      // Act - Pausamos el tracking
      // Atrapamos la excepción en caso de que el llamado a la API real falle por falta de internet
      try {
        await trackingService.pausarTracking(reporteId: 'rep_001', usuarioId: 'usr_001');
      } catch (_) {}
      
      // Assert - Comprobamos el estado tras pausar
      expect(trackingService.isPaused, true, reason: 'El sistema debe estar en estado Pausado.');
      expect(trackingService.isTracking, true, reason: 'Estar pausado NO significa que el tracking se terminó.');

      // Act - Reanudamos el tracking
      trackingService.reanudarTracking();
      
      // Assert - Comprobamos el estado tras reanudar
      expect(trackingService.isPaused, false, reason: 'El sistema debe volver a estar en captura activa (No pausado).');
    });

    test('4. Cierre del Operativo (Terminar Tracking): Liberación de memoria y timers', () async {
      // Arrange - Arrancamos
      await trackingService.iniciarTracking(reporteId: 'rep_001', usuarioId: 'usr_001');
      expect(trackingService.isTracking, true);
      
      // Act - Terminamos el tracking
      try {
        await trackingService.terminarTracking(reporteId: 'rep_001', usuarioId: 'usr_001');
      } catch (_) {}

      // Assert - Todo debe volver a estado cero
      expect(trackingService.isTracking, false, reason: 'El tracking debe apagarse completamente.');
      expect(trackingService.isPaused, false, reason: 'Los estados secundarios también deben limpiarse.');
      expect(trackingService.totalPuntos, 0, reason: 'Los puntos pendientes deben haber sido enviados/limpiados.');
    });
  });
}