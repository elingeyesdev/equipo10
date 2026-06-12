<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\UsuarioWebController;
use App\Http\Controllers\Web\ReporteWebController;
use App\Http\Controllers\Web\EncuestaWebController;
use App\Http\Controllers\Web\CategoriaWebController;
use App\Http\Controllers\Web\ConfiguracionWebController;
use App\Http\Controllers\Web\UserRoleController;
use App\Http\Controllers\GrupoController;
use App\Http\Controllers\Auth\LoginController;




use App\Http\Controllers\Auth\RegisterController;

Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('/login', [LoginController::class, 'login']);
Route::get('/register', [RegisterController::class, 'showRegisterForm'])->name('register');
Route::post('/register', [RegisterController::class, 'register']);
Route::post('/logout', [LoginController::class, 'logout'])->name('logout');


Route::get('/', function () {
    if (auth()->check()) {
        return redirect()->route('dashboard');
    }
    return redirect()->route('login');
});


    
    
    Route::get('/restricted', function () {
        return view('errors.restricted');
    })->name('restricted');

    
    Route::middleware(['check.site.access'])->group(function () {
        
        
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
        
        // Reseñas
        Route::get('/resenas', [EncuestaWebController::class, 'index'])->name('resenas.index');
        Route::resource('usuarios', UsuarioWebController::class);

        
        Route::prefix('grupos')->name('grupos.')->group(function () {
            Route::get('/', [GrupoController::class, 'index'])->name('index');
            Route::get('/{id}', [GrupoController::class, 'show'])->name('show');
            Route::post('/{id}/join', [GrupoController::class, 'join'])->name('join');
            Route::post('/{id}/leave', [GrupoController::class, 'leave'])->name('leave');
            
            Route::post('/', function (\Illuminate\Http\Request $request) {
                $validated = $request->validate([
                    'cuadrante_id' => 'required|exists:cuadrantes,id',
                    'nombre' => 'required|string|max:255',
                    'descripcion' => 'nullable|string',
                    'publico' => 'nullable|boolean',
                    'requiere_aprobacion' => 'nullable|boolean'
                ]);
                
                $grupo = \App\Models\Grupo::create($validated);
                
                return response()->json($grupo, 201);
            })->name('store');
        });

        
        Route::prefix('respuestas')->name('respuestas.')->group(function () {
            Route::get('/', function () {
                $respuestas = \App\Models\Respuesta::with(['reporte', 'usuario'])->orderBy('created_at', 'desc')->get();
                return view('respuestas.index', compact('respuestas'));
            })->name('index');
        });

        
        Route::prefix('notificaciones')->name('notificaciones.')->group(function () {
            Route::get('/', function () {
                $notificaciones = \App\Models\Notificacion::with('usuario')->orderBy('created_at', 'desc')->paginate(50);
                return view('notificaciones.index', compact('notificaciones'));
            })->name('index');
        });
    });

    
    Route::middleware(['auth', 'role_or_permission:administrador|editor|crear reportes|editar reportes'])->group(function () {
    Route::resource('reportes', ReporteWebController::class);
    // Cerrar búsqueda con motivo
    Route::put('/reportes/{reporte}/cerrar', [ReporteWebController::class, 'cerrar'])->name('reportes.cerrar');
    // Pausar búsqueda (suspensión temporal)
    Route::put('/reportes/{reporte}/pausar', [ReporteWebController::class, 'pausar'])->name('reportes.pausar');
    // Reanudar búsqueda (desde cerrada o pausada)
    Route::put('/reportes/{reporte}/reanudar', [ReporteWebController::class, 'reanudar'])->name('reportes.reanudar');
    // Guardar pista de búsqueda en un reporte (solo admin o creador, validado en controller)
    Route::post('/reportes/{reporte}/informacion', [ReporteWebController::class, 'guardarInformacion'])->name('reportes.informacion.store');
    // Eliminar informacion/evidencia desde el panel web
    Route::delete('/reportes/{reporte}/informacion/{infoId}', [ReporteWebController::class, 'eliminarInformacion'])->name('reportes.informacion.destroy');
    Route::put('/reportes/{reporte}/informacion/{infoId}/editar', [ReporteWebController::class, 'editarInformacion'])->name('reportes.informacion.editar');
    // Aprobar o rechazar evidencia desde el panel web
    Route::put('/reportes/{reporte}/informacion/{infoId}/aprobar', [ReporteWebController::class, 'aprobarEvidencia'])->name('reportes.informacion.aprobar');
    Route::put('/reportes/{reporte}/informacion/{infoId}/rechazar', [ReporteWebController::class, 'rechazarEvidencia'])->name('reportes.informacion.rechazar');
    });

    
    Route::prefix('reportes-estadisticos')->name('estadisticas.')->middleware(['auth', 'role:administrador|editor'])->group(function () {
        Route::get('/', [App\Http\Controllers\ReporteEstadisticoController::class, 'index'])->name('index');
        Route::get('/eficacia', [App\Http\Controllers\ReporteEstadisticoController::class, 'eficaciaCuadrante'])->name('eficacia');
        Route::get('/usuarios', [App\Http\Controllers\ReporteEstadisticoController::class, 'topUsuarios'])->name('usuarios');
        Route::get('/tendencias', [App\Http\Controllers\ReporteEstadisticoController::class, 'tendenciasTemporales'])->name('tendencias');
        Route::get('/exportar/pdf/{reporte}', [App\Http\Controllers\ReporteEstadisticoController::class, 'exportarPDF'])->name('exportar.pdf');
        Route::get('/exportar/excel/{reporte}', [App\Http\Controllers\ReporteEstadisticoController::class, 'exportarExcel'])->name('exportar.excel');
    });

    
    Route::middleware(['auth', 'role_or_permission:administrador|editor|crear categorias|editar categorias'])->group(function () {
    Route::resource('categorias', CategoriaWebController::class);
    });

    
    Route::prefix('cuadrantes')->name('cuadrantes.')->middleware(['auth', 'role:administrador|editor'])->group(function () {
        Route::get('/', [\App\Http\Controllers\Web\CuadranteWebController::class, 'index'])->name('index');
        Route::post('/', [\App\Http\Controllers\Web\CuadranteWebController::class, 'store'])->name('store');
        
        // Rutas del Editor Secreto (Temporales para configuracion inicial)
        Route::get('/editor-secreto', [\App\Http\Controllers\Web\CuadranteWebController::class, 'editor'])->name('editor');
        Route::post('/save-geometry', [\App\Http\Controllers\Web\CuadranteWebController::class, 'saveGeometry'])->name('save_geometry');
        Route::delete('/{cuadrante}', [\App\Http\Controllers\Web\CuadranteWebController::class, 'destroy'])->name('destroy');
    });



    
    Route::middleware(['auth', 'role:administrador'])->group(function () {
        Route::get('/configuracion', [ConfiguracionWebController::class, 'index'])->name('configuracion.index');
        Route::get('/configuracion/editar', [ConfiguracionWebController::class, 'edit'])->name('configuracion.edit');
        Route::put('/configuracion', [ConfiguracionWebController::class, 'update'])->name('configuracion.update');
    });

    
    Route::prefix('users')->name('users.')->middleware(['auth', 'role:administrador'])->group(function () {
        Route::prefix('roles')->name('roles.')->group(function () {
            Route::get('/', [UserRoleController::class, 'index'])->name('index');
            Route::get('/{id}/edit', [UserRoleController::class, 'edit'])->name('edit');
            Route::put('/{id}', [UserRoleController::class, 'update'])->name('update');
            Route::post('/{id}/assign', [UserRoleController::class, 'assignRole'])->name('assign');
            Route::delete('/{id}/remove', [UserRoleController::class, 'removeRole'])->name('remove');
        });
    });

    
    Route::prefix('test')->name('test.')->group(function () {
        
        Route::get('/permission', [\App\Http\Controllers\TestPermissionController::class, 'test'])->name('permission');
        
        
        Route::get('/admin', [\App\Http\Controllers\TestPermissionController::class, 'adminOnly'])
            ->middleware(['role:administrador'])
            ->name('admin');
            
        Route::get('/editor', [\App\Http\Controllers\TestPermissionController::class, 'editorOnly'])
            ->middleware(['role:editor'])
            ->name('editor');
    });
    
    // Fallback para servir imágenes en Windows sin necesidad de symlinks
    Route::get('/storage/{path}', function ($path) {
        $filePath = storage_path('app/public/' . $path);
        if (!file_exists($filePath)) {
            abort(404);
        }
        return response()->file($filePath);
    })->where('path', '.*');