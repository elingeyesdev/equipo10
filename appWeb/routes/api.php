<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CuadranteController;
use App\Http\Controllers\Api\GrupoController;
use App\Http\Controllers\Api\ReporteController;
use App\Http\Controllers\Api\RespuestaController;
use App\Http\Controllers\Api\NotificacionController;
use App\Http\Controllers\Api\CategoriaController;

/*
|--------------------------------------------------------------------------
| API Routes - Sistema de Reportes de Objetos Perdidos
|--------------------------------------------------------------------------
*/

// ============================================
// AUTENTICACIÓN
// ============================================
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::get('perfil/{usuarioId}', [AuthController::class, 'perfil']);
    Route::put('perfil/{usuarioId}', [AuthController::class, 'actualizarPerfil']);
    Route::put('ubicacion/{usuarioId}', [AuthController::class, 'actualizarUbicacion']);
    Route::put('notificaciones/{usuarioId}', [AuthController::class, 'actualizarNotificaciones']);
});

// ============================================
// CATEGORÍAS
// ============================================
Route::prefix('categorias')->group(function () {
    Route::get('/', [CategoriaController::class, 'index']);
    Route::get('/{id}', [CategoriaController::class, 'show']);
});

// ============================================
// CUADRANTES (Para HTML de generación)
// ============================================
Route::prefix('cuadrantes')->group(function () {
    // IMPORTANTE: Rutas específicas PRIMERO, rutas con parámetros DESPUÉS
    
    // Detectar cuadrante por ubicación
    Route::post('detectar', [CuadranteController::class, 'detectarCuadrante']);
    
    // Obtener 25 cuadrantes cercanos
    Route::post('cercanos', [CuadranteController::class, 'cuadrantesCercanos']);
    
    // Listar todos los cuadrantes
    Route::get('/', [CuadranteController::class, 'index']);
    
    // Crear cuadrante (desde HTML)
    Route::post('/', [CuadranteController::class, 'store']);
    
    // Agregar barrio a cuadrante
    Route::post('{cuadranteId}/barrios', [CuadranteController::class, 'agregarBarrio']);
    
    // Obtener 8 cuadrantes adyacentes
    Route::get('{cuadranteId}/adyacentes', [CuadranteController::class, 'cuadrantesAdyacentes']);
    
    // Obtener cuadrante específico (SIEMPRE AL FINAL)
    Route::get('{id}', [CuadranteController::class, 'show']);
});

// ============================================
// GRUPOS
// ============================================
Route::prefix('grupos')->group(function () {
    // IMPORTANTE: Rutas específicas PRIMERO
    
    // Unir usuario a grupo automáticamente
    Route::post('unir-automatico', [GrupoController::class, 'unirUsuarioAutomatico']);
    
    // Verificar y cambiar grupo automáticamente según ubicación
    Route::post('verificar-cambio-grupo', [GrupoController::class, 'verificarCambioGrupo']);
    
    // Obtener grupos por cuadrantes
    Route::post('por-cuadrantes', [GrupoController::class, 'gruposPorCuadrantes']);
    
    // Salir de un grupo
    Route::post('salir', [GrupoController::class, 'salirDelGrupo']);
    
    // Obtener grupos del usuario
    Route::get('usuario/{usuarioId}', [GrupoController::class, 'gruposDelUsuario']);
    
    // Listar todos los grupos
    Route::get('/', [GrupoController::class, 'index']);
    
    // Crear grupo (desde HTML)
    Route::post('/', [GrupoController::class, 'store']);
    
    // Obtener miembros de un grupo
    Route::get('{grupoId}/miembros', [GrupoController::class, 'miembrosDelGrupo']);
    
    // Obtener grupo específico (SIEMPRE AL FINAL)
    Route::get('{id}', [GrupoController::class, 'show']);
});

// ============================================
// REPORTES
// ============================================
Route::prefix('reportes')->group(function () {
    // IMPORTANTE: Rutas específicas PRIMERO
    
    // Verificar expansiones automáticas (ejecutar periódicamente)
    Route::post('verificar-expansiones', [ReporteController::class, 'verificarExpansionesAutomaticas']);
    
    // Obtener reportes del usuario
    Route::get('usuario/{usuarioId}', [ReporteController::class, 'reportesDelUsuario']);
    
    // Obtener reportes de un grupo
    Route::get('grupo/{grupoId}', [ReporteController::class, 'reportesDelGrupo']);
    
    // Crear reporte
    Route::post('/', [ReporteController::class, 'store']);
    
    // Expandir reporte manualmente
    Route::post('{reporteId}/expandir', [ReporteController::class, 'expandirReporte']);
    
    // 🧪 TESTING: Expandir reporte inmediatamente (ignora tiempo de espera)
    Route::post('{reporteId}/expandir-inmediato', [ReporteController::class, 'expandirInmediato']);
    
    // Marcar reporte como resuelto
    Route::put('{reporteId}/resuelto', [ReporteController::class, 'marcarResuelto']);
    
    // Obtener reporte específico (SIEMPRE AL FINAL)
    Route::get('{id}', [ReporteController::class, 'show']);
});

// ============================================
// RESPUESTAS
// ============================================
Route::prefix('respuestas')->group(function () {
    // IMPORTANTE: Rutas específicas PRIMERO
    
    // Obtener respuestas de un reporte
    Route::get('reporte/{reporteId}', [RespuestaController::class, 'respuestasDelReporte']);
    
    // Obtener solo respuestas tipo "encontrado"
    Route::get('reporte/{reporteId}/encontrado', [RespuestaController::class, 'respuestasEncontrado']);
    
    // Crear respuesta
    Route::post('/', [RespuestaController::class, 'store']);
    
    // Marcar respuesta como BIEN
    Route::put('{respuestaId}/bien', [RespuestaController::class, 'marcarBien']);
    
    // Marcar respuesta como ERRÓNEO
    Route::put('{respuestaId}/erroneo', [RespuestaController::class, 'marcarErroneo']);
    
    // Eliminar respuesta
    Route::delete('{id}', [RespuestaController::class, 'destroy']);
    
    // Obtener respuesta específica (SIEMPRE AL FINAL)
    Route::get('{id}', [RespuestaController::class, 'show']);
});

// ============================================
// NOTIFICACIONES
// ============================================
Route::prefix('notificaciones')->group(function () {
    // IMPORTANTE: Rutas específicas PRIMERO
    
    // Obtener todas las notificaciones del usuario
    Route::get('usuario/{usuarioId}', [NotificacionController::class, 'index']);
    
    // Obtener notificaciones no leídas
    Route::get('usuario/{usuarioId}/no-leidas', [NotificacionController::class, 'noLeidas']);
    
    // Marcar todas como leídas
    Route::put('usuario/{usuarioId}/marcar-todas-leidas', [NotificacionController::class, 'marcarTodasLeidas']);
    
    // Eliminar todas las notificaciones
    Route::delete('usuario/{usuarioId}/eliminar-todas', [NotificacionController::class, 'eliminarTodas']);
    
    // Marcar notificación como leída
    Route::put('{notificacionId}/leida', [NotificacionController::class, 'marcarLeida']);
    
    // Eliminar notificación
    Route::delete('{notificacionId}', [NotificacionController::class, 'destroy']);
});

// ============================================
// RUTA DE PRUEBA
// ============================================
Route::get('/ping', function () {
    return response()->json([
        'success' => true,
        'message' => 'API funcionando correctamente',
        'timestamp' => now()
    ]);
});