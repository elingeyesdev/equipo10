import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Servicio de caché de teselas (tiles) del mapa para el área operativa.
///
/// Estrategia: **Cache-First con Network-Fallback**.
///   1. Si el tile existe en disco  → se sirve inmediatamente (offline OK).
///   2. Si no existe y hay red       → se descarga, guarda en disco y se sirve.
///   3. Si no existe y no hay red    → lanza excepción para que flutter_map
///      muestre el placeholder de tile no disponible.
///
/// Estructura en disco:
///   `<appDocDir>/map_tile_cache/{storeName}/{z}/{x}/{y}.png`
///
/// E9.2 — Módulo Offline: Caché local de teselas del mapa para el área
/// operativa del cuadrante asignado.
class TileCacheService {
  static final TileCacheService _instance = TileCacheService._internal();
  factory TileCacheService() => _instance;
  TileCacheService._internal();

  /// Nombre del store principal de la app.
  static const String defaultStore = 'echoes_mapa_operativo';

  /// Zoom mínimo pre-descargado.
  static const int minZoom = 13;

  /// Zoom máximo pre-descargado — detalle para S&R sin exceder espacio.
  static const int maxZoom = 17;

  Directory? _appDocDir;

  // ── Rutas de archivos ──────────────────────────────────────────────────────

  Future<Directory> _storeDir(String storeName) async {
    _appDocDir ??= await getApplicationDocumentsDirectory();
    final dir = Directory('${_appDocDir!.path}/map_tile_cache/$storeName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _tileFile(int z, int x, int y, String storeName) async {
    final base = await _storeDir(storeName);
    return File('${base.path}/$z/$x/$y.png');
  }

  // ── API pública: lectura / escritura ──────────────────────────────────────

  /// Lee un tile desde disco. Retorna `null` si no está en caché.
  Future<Uint8List?> getTile(int z, int x, int y,
      {String storeName = defaultStore}) async {
    try {
      final file = await _tileFile(z, x, y, storeName);
      if (await file.exists()) return file.readAsBytes();
    } catch (e) {
      debugPrint('[TileCache] Error leyendo $z/$x/$y: $e');
    }
    return null;
  }

  /// Persiste un tile en disco.
  Future<void> saveTile(int z, int x, int y, Uint8List bytes,
      {String storeName = defaultStore}) async {
    try {
      final file = await _tileFile(z, x, y, storeName);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint('[TileCache] Error guardando $z/$x/$y: $e');
    }
  }

  // ── Estadísticas ───────────────────────────────────────────────────────────

  /// Número de tiles almacenados en el store.
  Future<int> contarTiles({String storeName = defaultStore}) async {
    try {
      final dir = await _storeDir(storeName);
      int count = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.png')) count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Tamaño total del caché en bytes.
  Future<int> tamanoBytes({String storeName = defaultStore}) async {
    try {
      final dir = await _storeDir(storeName);
      int size = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) size += await entity.length();
      }
      return size;
    } catch (_) {
      return 0;
    }
  }

  // ── Pre-descarga del área operativa ───────────────────────────────────────

  /// Descarga todos los tiles del bounding box del cuadrante para los
  /// zoom [minZoom]–[maxZoom] y los persiste en disco.
  ///
  /// Retorna la cantidad de tiles descargados con éxito.
  Future<int> preDescargarAreaOperativa({
    required double latMin,
    required double latMax,
    required double lngMin,
    required double lngMax,
    required String urlTemplate,
    Map<String, String> additionalOptions = const {},
    void Function(int completados, int total)? onProgress,
    String storeName = defaultStore,
  }) async {
    final tiles = <_TileCoord>[];
    for (int z = minZoom; z <= maxZoom; z++) {
      final topLeft = _latLngToTileXY(latMax, lngMin, z);
      final bottomRight = _latLngToTileXY(latMin, lngMax, z);
      for (int x = topLeft.x; x <= bottomRight.x; x++) {
        for (int y = topLeft.y; y <= bottomRight.y; y++) {
          tiles.add(_TileCoord(z, x, y));
        }
      }
    }

    final total = tiles.length;
    int completados = 0;
    onProgress?.call(0, total);
    debugPrint('[TileCache] Iniciando pre-descarga: $total tiles...');

    final client = http.Client();
    try {
      const batchSize = 4;
      for (int i = 0; i < tiles.length; i += batchSize) {
        final batch = tiles.sublist(i, (i + batchSize).clamp(0, tiles.length));
        await Future.wait(batch.map((t) async {
          final cached = await getTile(t.z, t.x, t.y, storeName: storeName);
          if (cached != null) {
            completados++;
            onProgress?.call(completados, total);
            return;
          }
          try {
            final url = _buildUrl(urlTemplate, t.z, t.x, t.y, additionalOptions);
            final resp =
                await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
            if (resp.statusCode == 200) {
              await saveTile(t.z, t.x, t.y, resp.bodyBytes, storeName: storeName);
              completados++;
            }
          } catch (_) {}
          onProgress?.call(completados, total);
        }));
      }
    } finally {
      client.close();
    }

    debugPrint('[TileCache] Pre-descarga finalizada: $completados/$total tiles OK');
    return completados;
  }

  /// Borra todos los tiles del store dado.
  Future<void> limpiarCache({String storeName = defaultStore}) async {
    try {
      final dir = await _storeDir(storeName);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('[TileCache] Error limpiando caché: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  _TileCoord _latLngToTileXY(double lat, double lng, int z) {
    final n = 1 << z;
    final latRad = lat * math.pi / 180.0;
    final x = ((lng + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
    final y = ((1.0 -
                    math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) /
                        math.pi) /
                2.0 *
                n)
        .floor()
        .clamp(0, n - 1);
    return _TileCoord(z, x, y);
  }

  String _buildUrl(String template, int z, int x, int y,
      Map<String, String> options) {
    String url = template
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
    options.forEach((k, v) => url = url.replaceAll('{$k}', v));
    return url;
  }
}

class _TileCoord {
  final int z, x, y;
  const _TileCoord(this.z, this.x, this.y);
}

// ── CachingTileProvider para flutter_map ──────────────────────────────────

/// [TileProvider] para [flutter_map] con estrategia Cache-First.
///
/// Uso:
/// ```dart
/// TileLayer(
///   urlTemplate: '...',
///   tileProvider: CachingTileProvider(),
/// )
/// ```
class CachingTileProvider extends TileProvider {
  final TileCacheService _cache = TileCacheService();
  final String storeName;
  final Map<String, String> additionalOptions;

  CachingTileProvider({
    this.storeName = TileCacheService.defaultStore,
    this.additionalOptions = const {},
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _AsyncTileImageProvider(
      fetchBytes: _fetchBytes(
        coordinates.z,
        coordinates.x,
        coordinates.y,
        options.urlTemplate ?? '',
      ),
      cacheKey: '${storeName}_${coordinates.z}_${coordinates.x}_${coordinates.y}',
    );
  }

  Future<Uint8List> _fetchBytes(
      int z, int x, int y, String urlTemplate) async {
    // 1. Caché
    final cached = await _cache.getTile(z, x, y, storeName: storeName);
    if (cached != null) return cached;

    // 2. Red
    final url = _buildUrl(urlTemplate, z, x, y);
    final client = http.Client();
    try {
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        unawaited(_cache.saveTile(z, x, y, bytes, storeName: storeName));
        return bytes;
      }
    } finally {
      client.close();
    }
    throw Exception('Tile $z/$x/$y no disponible');
  }

  String _buildUrl(String template, int z, int x, int y) {
    String url = template
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
    additionalOptions.forEach((k, v) => url = url.replaceAll('{$k}', v));
    return url;
  }
}

/// [ImageProvider] que carga tiles de forma asíncrona usando [dart:ui] directamente.
///
/// Funciona con Flutter 3.x (incluye 3.41+).
class _AsyncTileImageProvider extends ImageProvider<_AsyncTileImageProvider> {
  final Future<Uint8List> fetchBytes;
  final String cacheKey;

  const _AsyncTileImageProvider({
    required this.fetchBytes,
    required this.cacheKey,
  });

  @override
  Future<_AsyncTileImageProvider> obtainKey(ImageConfiguration config) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
      _AsyncTileImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _decodeBytes(decode),
      scale: 1.0,
      debugLabel: 'CachedTile_$cacheKey',
    );
  }

  Future<ui.Codec> _decodeBytes(ImageDecoderCallback decode) async {
    final bytes = await fetchBytes;
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is _AsyncTileImageProvider && cacheKey == other.cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}
