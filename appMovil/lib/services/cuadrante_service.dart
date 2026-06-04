import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/cuadrante_model.dart';
import 'api_service.dart';
import 'local_database.dart';
import 'connectivity_service.dart';

/// Servicio de cuadrantes con soporte offline.
///
/// Flujo:
///   - Con red   → consulta API, guarda resultado en [LocalDatabase], retorna datos frescos.
///   - Sin red   → retorna los cuadrantes guardados localmente en SQLite.
///
/// E9.3 — Módulo Offline: Almacenamiento local de cuadrantes del área
/// operativa en SQLite.
class CuadranteService {
  final ApiService _api = ApiService();
  final LocalDatabase _db = LocalDatabase();
  final ConnectivityService _connectivity = ConnectivityService();

  /// Obtiene la lista de cuadrantes.
  /// Cache-first si no hay red, network-first si hay conexión.
  Future<List<CuadranteModel>> getCuadrantes() async {
    if (!_connectivity.isOnline) {
      // Sin red: leer del caché local
      final local = await _db.getCuadrantes();
      if (local.isNotEmpty) {
        return local;
      }
      // No hay datos locales → retornar lista vacía
      return [];
    }

    // Con red: llamada al API
    try {
      final response = await _api.client.get('/cuadrantes');

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final cuadrantes =
            data.map((m) => CuadranteModel.fromMap(m)).toList();

        // E9.3 — Persistir en SQLite para uso offline futuro
        await _db.upsertCuadrantes(cuadrantes);

        return cuadrantes;
      }
      return await _db.getCuadrantes(); // Fallback a caché si el API falla
    } on DioException catch (e) {
      debugPrint('Error al obtener cuadrantes (red): $e');
      // Fallback a caché local ante cualquier error de red
      return _db.getCuadrantes();
    } catch (e) {
      debugPrint('Error al obtener cuadrantes: $e');
      return _db.getCuadrantes();
    }
  }

  /// Detecta el cuadrante que contiene el punto [lat, lng].
  /// Sin red: busca en los cuadrantes locales por bounding box.
  Future<CuadranteModel?> detectarCuadrante(double lat, double lng) async {
    if (!_connectivity.isOnline) {
      // Búsqueda local por bounding box
      final locales = await _db.getCuadrantes();
      try {
        return locales.firstWhere(
          (c) =>
              c.latMin != null &&
              c.latMax != null &&
              c.lngMin != null &&
              c.lngMax != null &&
              lat >= c.latMin! &&
              lat <= c.latMax! &&
              lng >= c.lngMin! &&
              lng <= c.lngMax!,
        );
      } catch (_) {
        return null;
      }
    }

    try {
      final response = await _api.client.post('/cuadrantes/detectar', data: {
        'lat': lat,
        'lng': lng,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final cuadrante = CuadranteModel.fromMap(response.data['data']);
        // Persistir este cuadrante individual también
        await _db.upsertCuadrantes([cuadrante]);
        return cuadrante;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Error al detectar cuadrante (red): $e');
      // Intentar detección local como fallback
      return detectarCuadrante(lat, lng);
    } catch (e) {
      debugPrint('Error al detectar cuadrante: $e');
      return null;
    }
  }
}
