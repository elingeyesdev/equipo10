<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reporte;
use App\Models\ReporteCaracteristica;
use App\Models\Cuadrante;
use App\Models\Categoria;
use App\Models\ExpansionReporte;
use App\Models\ConfiguracionSistema;
use App\Models\Grupo;
use App\Models\Notificacion;
use App\Models\NotificacionDato;
use App\Models\ReporteImagen;
use App\Models\ReporteVideo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ReporteController extends Controller
{
    /**
     * Crear reporte
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'usuario_id' => 'required|exists:usuarios,id',
            'categoria_id' => 'required|exists:categorias,id',
            'tipo_reporte' => 'required|in:perdido,encontrado',
            'titulo' => 'required|string|max:200',
            'descripcion' => 'required|string',
            'ubicacion_exacta_lat' => 'required|numeric|between:-90,90',
            'ubicacion_exacta_lng' => 'required|numeric|between:-180,180',
            'direccion_referencia' => 'nullable|string',
            'fecha_perdida' => 'nullable|date',
            'contacto_publico' => 'boolean',
            'telefono_contacto' => 'nullable|string|max:20',
            'email_contacto' => 'nullable|email',
            'recompensa' => 'nullable|numeric|min:0',
            'caracteristicas' => 'nullable|array',
            'imagenes' => 'nullable|array',
            'imagenes.*' => 'required|url',
            'videos' => 'nullable|array',
            'videos.*' => 'required|url'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();

            // Detectar cuadrante según ubicación
            $cuadrante = Cuadrante::where('activo', true)
                ->where('lat_min', '<=', $request->ubicacion_exacta_lat)
                ->where('lat_max', '>=', $request->ubicacion_exacta_lat)
                ->where('lng_min', '<=', $request->ubicacion_exacta_lng)
                ->where('lng_max', '>=', $request->ubicacion_exacta_lng)
                ->first();

            if (!$cuadrante) {
                return response()->json([
                    'success' => false,
                    'message' => 'No se encontró un cuadrante para esta ubicación'
                ], 404);
            }

            // Obtener configuración de expansión
            $tiempoExpansion = ConfiguracionSistema::where('clave', 'tiempo_expansion_horas')->first();
            $horasExpansion = $tiempoExpansion ? (float)$tiempoExpansion->valor : 24;
            
            // 🧪 PARA TESTING: Descomentar la siguiente línea para usar 5 minutos
            // $horasExpansion = 5 / 60; // 5 minutos = 0.083 horas

            // Crear reporte
            $reporte = Reporte::create([
                'usuario_id' => $request->usuario_id,
                'categoria_id' => $request->categoria_id,
                'cuadrante_id' => $cuadrante->id,
                'tipo_reporte' => $request->tipo_reporte,
                'titulo' => $request->titulo,
                'descripcion' => $request->descripcion,
                'ubicacion_exacta_lat' => $request->ubicacion_exacta_lat,
                'ubicacion_exacta_lng' => $request->ubicacion_exacta_lng,
                'direccion_referencia' => $request->direccion_referencia,
                'fecha_perdida' => $request->fecha_perdida,
                'fecha_reporte' => now(),
                'estado' => 'activo',
                'prioridad' => 'normal',
                'nivel_expansion' => 1,
                'max_expansion' => 3,
                'proxima_expansion' => now()->addHours($horasExpansion),
                'contacto_publico' => $request->contacto_publico ?? true,
                'telefono_contacto' => $request->telefono_contacto,
                'email_contacto' => $request->email_contacto,
                'recompensa' => $request->recompensa,
                'vistas' => 0
            ]);

            // Agregar características si existen
            if ($request->has('caracteristicas') && is_array($request->caracteristicas)) {
                foreach ($request->caracteristicas as $clave => $valor) {
                    ReporteCaracteristica::create([
                        'reporte_id' => $reporte->id,
                        'clave' => $clave,
                        'valor' => $valor
                    ]);
                }
            }

            // Agregar imágenes si existen
            if ($request->has('imagenes') && is_array($request->imagenes)) {
                foreach ($request->imagenes as $index => $url) {
                    ReporteImagen::create([
                        'reporte_id' => $reporte->id,
                        'url' => $url,
                        'orden' => $index + 1
                    ]);
                }
            }

            // Agregar videos si existen
            if ($request->has('videos') && is_array($request->videos)) {
                foreach ($request->videos as $index => $url) {
                    ReporteVideo::create([
                        'reporte_id' => $reporte->id,
                        'url' => $url,
                        'orden' => $index + 1
                    ]);
                }
            }

            // Registrar expansión inicial (nivel 1 = cuadrante original)
            ExpansionReporte::create([
                'reporte_id' => $reporte->id,
                'cuadrante_expandido_id' => $cuadrante->id,
                'nivel' => 1,
                'fecha_expansion' => now()
            ]);

            // Notificar a todos los miembros del grupo del cuadrante
            $this->notificarMiembrosGrupo($cuadrante->id, $reporte);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Reporte creado exitosamente',
                'data' => $reporte->load(['categoria', 'cuadrante', 'caracteristicas', 'imagenes', 'videos'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al crear reporte',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Expandir reporte a cuadrantes adyacentes
     */
    public function expandirReporte($reporteId)
    {
        try {
            DB::beginTransaction();

            $reporte = Reporte::with('cuadrante')->findOrFail($reporteId);

            // Verificar si ya pasó el tiempo de expansión
            if ($reporte->proxima_expansion && now()->lt($reporte->proxima_expansion)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Aún no es tiempo de expandir este reporte',
                    'proxima_expansion' => $reporte->proxima_expansion
                ], 400);
            }

            // Verificar si ya alcanzó el máximo de expansión
            if ($reporte->nivel_expansion >= $reporte->max_expansion) {
                return response()->json([
                    'success' => false,
                    'message' => 'El reporte ya alcanzó su máximo nivel de expansión'
                ], 400);
            }

            // Verificar si el reporte está activo
            if ($reporte->estado !== 'activo') {
                return response()->json([
                    'success' => false,
                    'message' => 'El reporte no está activo'
                ], 400);
            }

            // Obtener cuadrantes adyacentes
            $cuadranteOrigen = $reporte->cuadrante;
            $fila = $cuadranteOrigen->fila;
            $columna = $cuadranteOrigen->columna;

            $filaAnterior = chr(ord($fila) - 1);
            $filaSiguiente = chr(ord($fila) + 1);
            $columnaAnterior = $columna - 1;
            $columnaSiguiente = $columna + 1;

            $adyacentes = Cuadrante::where('activo', true)
                ->where(function($query) use ($fila, $filaAnterior, $filaSiguiente, $columna, $columnaAnterior, $columnaSiguiente) {
                    $query->orWhere(function($q) use ($filaAnterior, $columnaAnterior) {
                        $q->where('fila', $filaAnterior)->where('columna', $columnaAnterior);
                    })
                    ->orWhere(function($q) use ($filaAnterior, $columna) {
                        $q->where('fila', $filaAnterior)->where('columna', $columna);
                    })
                    ->orWhere(function($q) use ($filaAnterior, $columnaSiguiente) {
                        $q->where('fila', $filaAnterior)->where('columna', $columnaSiguiente);
                    })
                    ->orWhere(function($q) use ($fila, $columnaAnterior) {
                        $q->where('fila', $fila)->where('columna', $columnaAnterior);
                    })
                    ->orWhere(function($q) use ($fila, $columnaSiguiente) {
                        $q->where('fila', $fila)->where('columna', $columnaSiguiente);
                    })
                    ->orWhere(function($q) use ($filaSiguiente, $columnaAnterior) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columnaAnterior);
                    })
                    ->orWhere(function($q) use ($filaSiguiente, $columna) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columna);
                    })
                    ->orWhere(function($q) use ($filaSiguiente, $columnaSiguiente) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columnaSiguiente);
                    });
                })
                ->get();

            $nuevoNivel = $reporte->nivel_expansion + 1;
            $cuadrantesExpandidos = [];

            // Registrar expansión a cada cuadrante adyacente
            foreach ($adyacentes as $adyacente) {
                // Verificar si ya fue expandido a este cuadrante
                $yaExpandido = ExpansionReporte::where('reporte_id', $reporte->id)
                    ->where('cuadrante_expandido_id', $adyacente->id)
                    ->exists();

                if (!$yaExpandido) {
                    ExpansionReporte::create([
                        'reporte_id' => $reporte->id,
                        'cuadrante_expandido_id' => $adyacente->id,
                        'nivel' => $nuevoNivel,
                        'fecha_expansion' => now()
                    ]);

                    $cuadrantesExpandidos[] = $adyacente;

                    // Notificar a miembros del nuevo cuadrante
                    $this->notificarMiembrosGrupo($adyacente->id, $reporte);
                }
            }

            // Actualizar nivel de expansión del reporte
            $reporte->update([
                'nivel_expansion' => $nuevoNivel,
                'proxima_expansion' => null // Ya no se expande más
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Reporte expandido exitosamente',
                'data' => [
                    'reporte' => $reporte,
                    'nuevo_nivel' => $nuevoNivel,
                    'cuadrantes_expandidos' => $cuadrantesExpandidos,
                    'total_expandidos' => count($cuadrantesExpandidos)
                ]
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al expandir reporte',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Expandir reporte inmediatamente (SOLO PARA TESTING)
     * Ignora el tiempo de espera
     */
    public function expandirInmediato($reporteId)
    {
        try {
            DB::beginTransaction();

            $reporte = Reporte::with('cuadrante')->findOrFail($reporteId);

            // Verificar si ya alcanzó el máximo de expansión
            if ($reporte->nivel_expansion >= $reporte->max_expansion) {
                return response()->json([
                    'success' => false,
                    'message' => 'El reporte ya alcanzó su máximo nivel de expansión'
                ], 400);
            }

            // Verificar si el reporte está activo
            if ($reporte->estado !== 'activo') {
                return response()->json([
                    'success' => false,
                    'message' => 'El reporte no está activo'
                ], 400);
            }

            // Obtener cuadrantes adyacentes
            $cuadranteOrigen = $reporte->cuadrante;
            $fila = $cuadranteOrigen->fila;
            $columna = $cuadranteOrigen->columna;

            $filaAnterior = chr(ord($fila) - 1);
            $filaSiguiente = chr(ord($fila) + 1);
            $columnaAnterior = $columna - 1;
            $columnaSiguiente = $columna + 1;

            $adyacentes = Cuadrante::where('activo', true)
                ->where(function($query) use ($fila, $filaAnterior, $filaSiguiente, $columna, $columnaAnterior, $columnaSiguiente) {
                    $query->orWhere(function($q) use ($filaAnterior, $columnaAnterior) {
                        $q->where('fila', $filaAnterior)->where('columna', $columnaAnterior);
                    })
                    ->orWhere(function($q) use ($filaAnterior, $columna) {
                        $q->where('fila', $filaAnterior)->where('columna', $columna);
                    })
                    ->orWhere(function($q) use ($filaAnterior, $columnaSiguiente) {
                        $q->where('fila', $filaAnterior)->where('columna', $columnaSiguiente);
                    })
                    ->orWhere(function($q) use ($fila, $columnaAnterior) {
                        $q->where('fila', $fila)->where('columna', $columnaAnterior);
                    })
                    ->orWhere(function($q) use ($fila, $columnaSiguiente) {
                        $q->where('fila', $fila)->where('columna', $columnaSiguiente);
                    })
                    ->orWhere(function($q) use ($filaSiguiente, $columnaAnterior) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columnaAnterior);
                    })
                    ->orWhere(function($q) use ($filaSiguiente, $columna) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columna);
                    })
                    ->orWhere(function($q) use ($filaSiguiente, $columnaSiguiente) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columnaSiguiente);
                    });
                })
                ->get();

            $nuevoNivel = $reporte->nivel_expansion + 1;
            $cuadrantesExpandidos = [];

            // Registrar expansión a cada cuadrante adyacente
            foreach ($adyacentes as $adyacente) {
                // Verificar si ya fue expandido a este cuadrante
                $yaExpandido = ExpansionReporte::where('reporte_id', $reporte->id)
                    ->where('cuadrante_expandido_id', $adyacente->id)
                    ->exists();

                if (!$yaExpandido) {
                    ExpansionReporte::create([
                        'reporte_id' => $reporte->id,
                        'cuadrante_expandido_id' => $adyacente->id,
                        'nivel' => $nuevoNivel,
                        'fecha_expansion' => now()
                    ]);

                    $cuadrantesExpandidos[] = $adyacente;

                    // Notificar a miembros del nuevo cuadrante
                    $this->notificarMiembrosGrupo($adyacente->id, $reporte);
                }
            }

            // Actualizar nivel de expansión del reporte
            $reporte->update([
                'nivel_expansion' => $nuevoNivel,
                'proxima_expansion' => null // Ya no se expande más
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => '⚡ Reporte expandido INMEDIATAMENTE (modo testing)',
                'data' => [
                    'reporte' => $reporte,
                    'nuevo_nivel' => $nuevoNivel,
                    'cuadrantes_expandidos' => $cuadrantesExpandidos,
                    'total_expandidos' => count($cuadrantesExpandidos)
                ]
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al expandir reporte',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Verificar y expandir reportes automáticamente
     */
    public function verificarExpansionesAutomaticas()
    {
        try {
            // Buscar reportes que necesitan expandirse
            $reportes = Reporte::where('estado', 'activo')
                ->where('nivel_expansion', '<', DB::raw('max_expansion'))
                ->where('proxima_expansion', '<=', now())
                ->get();

            $expandidos = [];

            foreach ($reportes as $reporte) {
                $resultado = $this->expandirReporte($reporte->id);
                if ($resultado->getStatusCode() === 200) {
                    $expandidos[] = $reporte->id;
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Verificación completada',
                'data' => [
                    'reportes_verificados' => $reportes->count(),
                    'reportes_expandidos' => count($expandidos)
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al verificar expansiones',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener reportes de un grupo
     */
    public function reportesDelGrupo($grupoId)
    {
        try {
            $grupo = Grupo::findOrFail($grupoId);

            // Obtener todos los reportes del cuadrante del grupo
            // incluyendo expansiones a este cuadrante
            $reportes = Reporte::where(function($query) use ($grupo) {
                    $query->where('cuadrante_id', $grupo->cuadrante_id)
                          ->orWhereHas('expansiones', function($q) use ($grupo) {
                              $q->where('cuadrante_expandido_id', $grupo->cuadrante_id);
                          });
                })
                ->where('estado', 'activo')
                ->with(['categoria', 'usuario', 'caracteristicas', 'imagenes', 'videos'])
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'grupo' => $grupo,
                    'reportes' => $reportes,
                    'total' => $reportes->count()
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener reportes del grupo',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener reportes del usuario
     */
    public function reportesDelUsuario($usuarioId)
    {
        try {
            $reportes = Reporte::where('usuario_id', $usuarioId)
                ->with(['categoria', 'cuadrante', 'caracteristicas', 'imagenes', 'videos', 'respuestas'])
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $reportes
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener reportes del usuario',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener un reporte específico
     */
    public function show($id)
    {
        try {
            $reporte = Reporte::with([
                'categoria',
                'usuario',
                'cuadrante',
                'caracteristicas',
                'imagenes',
                'videos',
                'respuestas.usuario',
                'respuestas.imagenes',
                'respuestas.videos',
                'expansiones.cuadranteExpandido'
            ])->findOrFail($id);

            // Incrementar vistas
            $reporte->increment('vistas');

            return response()->json([
                'success' => true,
                'data' => $reporte
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Reporte no encontrado',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Cambiar estado del reporte a resuelto
     */
    public function marcarResuelto($reporteId)
    {
        try {
            $reporte = Reporte::findOrFail($reporteId);

            $reporte->update([
                'estado' => 'resuelto'
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Reporte marcado como resuelto',
                'data' => $reporte
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al marcar reporte como resuelto',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Notificar a miembros de un grupo
     */
    private function notificarMiembrosGrupo($cuadranteId, $reporte)
    {
        $grupo = Grupo::where('cuadrante_id', $cuadranteId)->first();

        if (!$grupo) {
            \Log::warning("No se encontró grupo para cuadrante: {$cuadranteId}");
            return;
        }

        $miembros = $grupo->usuarios()->get();

        foreach ($miembros as $miembro) {
            // No notificar al creador del reporte
            if ($miembro->id === $reporte->usuario_id) {
                continue;
            }

            \Log::info("Notificando a: {$miembro->id} - {$miembro->nombre}");

            $notificacion = Notificacion::create([
                'usuario_id' => $miembro->id,
                'tipo' => 'nuevo_reporte',
                'titulo' => 'Nuevo reporte en tu zona',
                'mensaje' => "Se ha reportado: {$reporte->titulo}",
                'leida' => false,
                'enviada_push' => false,
                'enviada_email' => false
            ]);

            \Log::info("Notificación creada: {$notificacion->id}");

            // Agregar datos adicionales
            NotificacionDato::create([
                'notificacion_id' => $notificacion->id,
                'clave' => 'reporte_id',
                'valor' => $reporte->id
            ]);

            NotificacionDato::create([
                'notificacion_id' => $notificacion->id,
                'clave' => 'grupo_id',
                'valor' => $grupo->id
            ]);
        }
    }
}

