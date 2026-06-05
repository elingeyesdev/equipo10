import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/cuadrante_model.dart';
import '../models/reporte_model.dart';

/// Base de datos local SQLite para el almacenamiento offline del módulo
/// operativo de Echoes.
///
/// Tablas:
///   - [cuadrantes]   : cuadrantes del área asignada al voluntario.
///   - [reportes]     : fichas/reportes del feed para lectura sin red.
///   - [pistas]       : pistas de información del mapa operativo.
///
/// Estrategia: los servicios de red guardan aquí cada respuesta exitosa.
/// Cuando [ConnectivityService.isOnline] es false, los ViewModels leen
/// directamente de esta BD sin tocar la red.
///
/// E9.3 — Módulo Offline: Almacenamiento local (SQLite) para los datos
/// del cuadrante asignado.
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  static const int _version = 1;
  static const String _dbName = 'echoes_offline.db';

  Database? _db;

  // ── Apertura / inicialización ──────────────────────────────────────────────

  Future<Database> get database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cuadrantes (
        id          TEXT PRIMARY KEY,
        codigo      TEXT NOT NULL,
        nombre      TEXT NOT NULL,
        zona        TEXT,
        ciudad      TEXT,
        geometria   TEXT,
        centro_lat  REAL NOT NULL DEFAULT 0,
        centro_lng  REAL NOT NULL DEFAULT 0,
        lat_min     REAL,
        lat_max     REAL,
        lng_min     REAL,
        lng_max     REAL,
        guardado_en TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reportes (
        id                   TEXT PRIMARY KEY,
        usuario_id           TEXT NOT NULL,
        categoria_id         TEXT,
        cuadrante_id         TEXT,
        tipo_reporte         TEXT NOT NULL,
        titulo               TEXT NOT NULL,
        descripcion          TEXT NOT NULL,
        lat                  REAL,
        lng                  REAL,
        estado               TEXT NOT NULL,
        primera_imagen       TEXT,
        nombre_categoria     TEXT,
        nombre_usuario       TEXT,
        prioridad            TEXT,
        fecha_perdida        TEXT,
        nivel_expansion      INTEGER NOT NULL DEFAULT 1,
        caracteristicas_json TEXT,
        created_at           TEXT,
        guardado_en          TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pistas (
        id              TEXT PRIMARY KEY,
        reporte_id      TEXT NOT NULL,
        cuadrante_id    TEXT,
        etiqueta        TEXT NOT NULL,
        descripcion     TEXT,
        lat             REAL NOT NULL,
        lng             REAL NOT NULL,
        fecha           TEXT,
        hora            TEXT,
        guardado_en     TEXT NOT NULL
      )
    ''');

    debugPrint('[LocalDB] Base de datos creada (v$version).');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Para futuras migraciones: añadir columnas aquí sin romper datos existentes.
    debugPrint('[LocalDB] Migración de v$oldVersion a v$newVersion.');
  }

  // ── CUADRANTES ─────────────────────────────────────────────────────────────

  /// Guarda una lista de cuadrantes (upsert: reemplaza si ya existe).
  Future<void> upsertCuadrantes(List<CuadranteModel> cuadrantes) async {
    if (kIsWeb) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final c in cuadrantes) {
      batch.insert(
        'cuadrantes',
        {
          'id': c.id,
          'codigo': c.codigo,
          'nombre': c.nombre,
          'zona': c.zona,
          'ciudad': c.ciudad,
          'geometria': c.geometria != null ? jsonEncode(c.geometria) : null,
          'centro_lat': c.centroLat,
          'centro_lng': c.centroLng,
          'lat_min': c.latMin,
          'lat_max': c.latMax,
          'lng_min': c.lngMin,
          'lng_max': c.lngMax,
          'guardado_en': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[LocalDB] ${cuadrantes.length} cuadrantes guardados.');
  }

  /// Lee todos los cuadrantes almacenados localmente.
  Future<List<CuadranteModel>> getCuadrantes() async {
    if (kIsWeb) return [];
    final db = await database;
    final rows = await db.query('cuadrantes');
    return rows.map((r) {
      // Deserializar geometría si existe
      Map<String, dynamic>? geo;
      if (r['geometria'] != null) {
        try {
          geo = jsonDecode(r['geometria'] as String);
        } catch (_) {}
      }
      return CuadranteModel(
        id: r['id'] as String,
        codigo: r['codigo'] as String,
        nombre: r['nombre'] as String,
        zona: r['zona'] as String?,
        ciudad: r['ciudad'] as String?,
        geometria: geo,
        centroLat: (r['centro_lat'] as num).toDouble(),
        centroLng: (r['centro_lng'] as num).toDouble(),
        latMin: r['lat_min'] != null ? (r['lat_min'] as num).toDouble() : null,
        latMax: r['lat_max'] != null ? (r['lat_max'] as num).toDouble() : null,
        lngMin: r['lng_min'] != null ? (r['lng_min'] as num).toDouble() : null,
        lngMax: r['lng_max'] != null ? (r['lng_max'] as num).toDouble() : null,
      );
    }).toList();
  }

  // ── REPORTES ───────────────────────────────────────────────────────────────

  /// Guarda una lista de reportes del feed (upsert).
  Future<void> upsertReportes(List<ReporteModel> reportes) async {
    if (kIsWeb) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final r in reportes) {
      batch.insert(
        'reportes',
        {
          'id': r.id,
          'usuario_id': r.usuarioId,
          'categoria_id': r.categoriaId,
          'cuadrante_id': r.cuadranteId,
          'tipo_reporte': r.tipoReporte,
          'titulo': r.titulo,
          'descripcion': r.descripcion,
          'lat': r.latitud,
          'lng': r.longitud,
          'estado': r.estado,
          'primera_imagen': r.primeraImagen,
          'nombre_categoria': r.nombreCategoria,
          'nombre_usuario': r.nombreUsuario,
          'prioridad': r.prioridad,
          'fecha_perdida': r.fechaPerdida,
          'nivel_expansion': r.nivelExpansion,
          'caracteristicas_json':
              r.caracteristicas != null ? jsonEncode(r.caracteristicas) : null,
          'created_at': r.createdAt?.toIso8601String(),
          'guardado_en': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[LocalDB] ${reportes.length} reportes guardados.');
  }

  /// Lee todos los reportes almacenados localmente, ordenados por fecha desc.
  Future<List<ReporteModel>> getReportes() async {
    if (kIsWeb) return [];
    final db = await database;
    final rows =
        await db.query('reportes', orderBy: 'created_at DESC');
    return rows.map((r) {
      Map<String, dynamic>? chars;
      if (r['caracteristicas_json'] != null) {
        try {
          chars = jsonDecode(r['caracteristicas_json'] as String);
        } catch (_) {}
      }
      return ReporteModel(
        id: r['id'] as String,
        usuarioId: r['usuario_id'] as String,
        categoriaId: r['categoria_id'] as String?,
        cuadranteId: r['cuadrante_id'] as String?,
        tipoReporte: r['tipo_reporte'] as String,
        titulo: r['titulo'] as String,
        descripcion: r['descripcion'] as String,
        latitud: r['lat'] != null ? (r['lat'] as num).toDouble() : null,
        longitud: r['lng'] != null ? (r['lng'] as num).toDouble() : null,
        estado: r['estado'] as String,
        primeraImagen: r['primera_imagen'] as String?,
        nombreCategoria: r['nombre_categoria'] as String?,
        nombreUsuario: r['nombre_usuario'] as String?,
        prioridad: r['prioridad'] as String?,
        fechaPerdida: r['fecha_perdida'] as String?,
        nivelExpansion:
            r['nivel_expansion'] != null ? (r['nivel_expansion'] as int) : 1,
        caracteristicas: chars,
        createdAt: r['created_at'] != null
            ? DateTime.tryParse(r['created_at'] as String)
            : null,
      );
    }).toList();
  }

  // ── PISTAS ────────────────────────────────────────────────────────────────

  /// Guarda una lista de pistas del mapa operativo (upsert).
  Future<void> upsertPistas(
      String reporteId, List<Map<String, dynamic>> pistas) async {
    if (kIsWeb) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final p in pistas) {
      batch.insert(
        'pistas',
        {
          'id': p['id']?.toString() ?? '${reporteId}_${p['lat']}_${p['lng']}',
          'reporte_id': reporteId,
          'cuadrante_id': p['cuadrante_id']?.toString(),
          'etiqueta': p['etiqueta']?.toString() ?? '',
          'descripcion': p['descripcion']?.toString(),
          'lat': (p['lat'] as num?)?.toDouble() ?? 0.0,
          'lng': (p['lng'] as num?)?.toDouble() ?? 0.0,
          'fecha': p['fecha']?.toString(),
          'hora': p['hora']?.toString(),
          'guardado_en': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[LocalDB] ${pistas.length} pistas guardadas para $reporteId.');
  }

  /// Lee las pistas de un reporte específico.
  Future<List<Map<String, dynamic>>> getPistas(String reporteId) async {
    if (kIsWeb) return [];
    final db = await database;
    return db.query(
      'pistas',
      where: 'reporte_id = ?',
      whereArgs: [reporteId],
    );
  }

  // ── Utilidades ─────────────────────────────────────────────────────────────

  /// Elimina todos los datos de la BD (útil al cerrar sesión).
  Future<void> limpiarTodo() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('cuadrantes');
    await db.delete('reportes');
    await db.delete('pistas');
    debugPrint('[LocalDB] Base de datos limpiada.');
  }

  /// Retorna estadísticas rápidas del contenido de la BD.
  Future<Map<String, int>> estadisticas() async {
    if (kIsWeb) return {'cuadrantes': 0, 'reportes': 0, 'pistas': 0};
    final db = await database;
    final c = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM cuadrantes'));
    final r = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM reportes'));
    final pi = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM pistas'));
    return {'cuadrantes': c ?? 0, 'reportes': r ?? 0, 'pistas': pi ?? 0};
  }

  /// Cierra la conexión a la BD (normalmente no es necesario en apps Flutter).
  Future<void> close() async {
    if (kIsWeb) return;
    await _db?.close();
    _db = null;
  }
}
