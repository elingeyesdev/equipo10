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
use App\Models\ImagenAlmacenada;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use App\Services\FcmService;
use App\Services\NotificacionPlantillas;

class ReporteController extends Controller
{
    /**
     * Obtener el Feed General (Todos los reportes activos globales)
     */
    public function index(Request $request)
    {
        // Auto-create storage symlink if missing so images work
        try {
            if (!file_exists(public_path('storage'))) {
                app('files')->link(storage_path('app/public'), public_path('storage'));
            }
        } catch (\Exception $e) {}

        try {
            $query = Reporte::with(['categoria', 'usuario', 'cuadrante']);

            if ($request->has('estado') && in_array($request->estado, ['activo', 'pausado', 'resuelto', 'terminado'])) {
                $query->where('estado', $request->estado);
            } elseif ($request->has('estado') && $request->estado === 'todos') {
                // Return all
            } else {
                $query->whereIn('estado', ['activo', 'pausado', 'resuelto', 'terminado']);
            }

            if ($request->has('tipo_reporte')) {
                $tipo = $request->tipo_reporte;
                if ($tipo == 'desaparicion') {
                    $query->whereHas('categoria', function($q) { 
                        $q->where('nombre', 'ilike', '%persona%')
                          ->orWhere('nombre', 'ilike', '%desaparicion%'); 
                    });
                } elseif ($tipo == 'mascota') {
                    $query->whereHas('categoria', function($q) { 
                        $q->where('nombre', 'ilike', '%mascota%'); 
                    });
                } elseif ($tipo == 'objeto') {
                    $query->whereHas('categoria', function($q) { 
                        $q->where('nombre', 'not ilike', '%persona%')
                          ->where('nombre', 'not ilike', '%desaparicion%')
                          ->where('nombre', 'not ilike', '%mascota%'); 
                    });
                } else {
                    $query->where('tipo_reporte', $tipo);
                }
            }

            if ($request->has('lat') && $request->has('lng') && $request->has('radio')) {
                $lat = (float) $request->lat;
                $lng = (float) $request->lng;
                $radio = (float) $request->radio;

                $query->whereNotNull('ubicacion_exacta_lat')
                      ->whereNotNull('ubicacion_exacta_lng')
                      ->whereRaw(
                          "(6371 * acos(cos(radians(?)) * cos(radians(ubicacion_exacta_lat)) * cos(radians(ubicacion_exacta_lng) - radians(?)) + sin(radians(?)) * sin(radians(ubicacion_exacta_lat)))) <= ?",
                          [$lat, $lng, $lat, $radio]
                      );
            }

            $reportes = $query->orderBy('created_at', 'desc')->get();

            return response()->json([
                'success' => true,
                'data' => $reportes
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener reportes',
                'error' => $e->getMessage()
            ], 500);
        }
    }

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

            // Detectar cuadrante: priorizar el enviado por la app, sino usar detección precisa
            $cuadranteId = $request->cuadrante_id;
            if ($cuadranteId === 'null' || $cuadranteId === 'undefined' || trim($cuadranteId) === '') {
                $cuadranteId = null;
            }
            
            if (!$cuadranteId) {
                $cuadrante = Cuadrante::detectByLocation($request->ubicacion_exacta_lat, $request->ubicacion_exacta_lng);
                $cuadranteId = $cuadrante?->id;
            }

            if (!$cuadranteId) {
                return response()->json([
                    'success' => false,
                    'message' => 'La ubicación seleccionada está fuera de la zona de búsqueda permitida'
                ], 422);
            }

            // Obtener configuración de expansión
            $tiempoExpansion = ConfiguracionSistema::where('clave', 'tiempo_expansion_horas')->first();
            $horasExpansion = $tiempoExpansion ? (float)$tiempoExpansion->valor : 24;
            
            // PARA TESTING: Descomentar la siguiente linea para usar 5 minutos
            // $horasExpansion = 5 / 60; // 5 minutos = 0.083 horas

            // Crear reporte con nueva lógica de expansión escalonada (10 niveles)
            $reporte = Reporte::create([
                'usuario_id' => $request->usuario_id,
                'categoria_id' => $request->categoria_id,
                'cuadrante_id' => $cuadranteId,
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
                'max_expansion' => 10, // Hasta 10 anillos de crecimiento
                'proxima_expansion' => now()->addMinutes(30), // Primer nivel a los 30 min
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
                // Notify the report creator about new pending evidences
                $notif = \App\Models\Notificacion::create([
                    'usuario_id' => $reporte->usuario_id,
                    'tipo' => 'evidencia_subida',
                    'titulo' => 'Nueva evidencia pendiente',
                    'mensaje' => 'Se ha subido una nueva evidencia al reporte que requiere tu aprobación.',
                    'leida' => false,
                    'enviada_push' => false,
                    'enviada_email' => false,
                ]);

                \App\Models\NotificacionDato::create([
                    'notificacion_id' => $notif->id,
                    'clave' => 'reporte_id',
                    'valor' => $reporte->id
                ]);
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

            // Registrar expansión inicial solo si hay cuadrante
            if ($cuadranteId) {
                ExpansionReporte::create([
                    'reporte_id' => $reporte->id,
                    'cuadrante_expandido_id' => $cuadranteId,
                    'nivel' => 1,
                    'fecha_expansion' => now()
                ]);

                // Notificar a todos los miembros del grupo del cuadrante
                $this->notificarMiembrosGrupo($cuadranteId, $reporte);
            }


            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Reporte creado exitosamente',
                'data' => $reporte->load(['categoria', 'cuadrante', 'caracteristicas', 'imagenes', 'videos'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error($e);
            return response()->json([
                'success' => false,
                'message' => 'Error al crear reporte: ' . $e->getMessage(),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }

    /**
     * Actualizar reporte (Edición libre)
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'titulo' => 'sometimes|required|string|max:200',
            'descripcion' => 'sometimes|required|string',
            'imagenes' => 'nullable|array',
            'imagenes.*' => 'required|url',
            'telefono_contacto' => 'nullable|string|max:20',
            'recompensa' => 'nullable|numeric|min:0',
            'direccion_referencia' => 'nullable|string|max:255',
            'fecha_perdida' => 'nullable|date',
            'caracteristicas' => 'nullable|array',
            'ubicacion_exacta_lat' => 'nullable|numeric',
            'ubicacion_exacta_lng' => 'nullable|numeric',
            'cuadrante_id' => 'nullable|exists:cuadrantes,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();
            $reporte = Reporte::findOrFail($id);
            
            if ($request->has('titulo')) {
                $reporte->titulo = $request->titulo;
            }
            if ($request->has('descripcion')) {
                $reporte->descripcion = $request->descripcion;
            }
            if ($request->has('telefono_contacto')) {
                $reporte->telefono_contacto = $request->telefono_contacto;
            }
            if ($request->has('recompensa')) {
                $reporte->recompensa = $request->recompensa;
            }
            if ($request->has('direccion_referencia')) {
                $reporte->direccion_referencia = $request->direccion_referencia;
            }
            if ($request->has('fecha_perdida')) {
                $reporte->fecha_perdida = $request->fecha_perdida;
            }
            if ($request->has('ubicacion_exacta_lat')) {
                $reporte->ubicacion_exacta_lat = $request->ubicacion_exacta_lat;
            }
            if ($request->has('ubicacion_exacta_lng')) {
                $reporte->ubicacion_exacta_lng = $request->ubicacion_exacta_lng;
            }
            if ($request->has('cuadrante_id')) {
                $reporte->cuadrante_id = $request->cuadrante_id;
            }

            // Reemplazar imágenes si se enviaron nuevas
            if ($request->has('imagenes') && is_array($request->imagenes) && count($request->imagenes) > 0) {
                ReporteImagen::where('reporte_id', $reporte->id)->delete();
                foreach ($request->imagenes as $index => $url) {
                    ReporteImagen::create([
                        'reporte_id' => $reporte->id,
                        'url' => $url,
                        'orden' => $index + 1
                    ]);
                }
                
            }

            $reporte->save();

            // Recrear características
            if ($request->has('caracteristicas') && is_array($request->caracteristicas)) {
                ReporteCaracteristica::where('reporte_id', $reporte->id)->delete();
                foreach ($request->caracteristicas as $clave => $valor) {
                    ReporteCaracteristica::create([
                        'reporte_id' => $reporte->id,
                        'clave' => $clave,
                        'valor' => $valor
                    ]);
                }
            }

            // Notificar a los voluntarios inscritos sobre la actualización
            $voluntarios = \App\Models\ReporteVoluntario::where('reporte_id', $reporte->id)
                ->whereIn('estado', ['buscando', 'esperando'])
                ->get();
            
            foreach ($voluntarios as $voluntario) {
                // No notificar al creador del reporte si por casualidad es voluntario
                if ($voluntario->usuario_id === $reporte->usuario_id) continue;
                
                $notif = \App\Models\Notificacion::create([
                    'usuario_id' => $voluntario->usuario_id,
                    'tipo' => 'actualizacion_reporte',
                    'titulo' => 'Reporte Actualizado',
                    'mensaje' => "El creador ha modificado los detalles del reporte: {$reporte->titulo}",
                    'leida' => false,
                    'enviada_push' => false,
                    'enviada_email' => false,
                ]);

                \App\Models\NotificacionDato::create([
                    'notificacion_id' => $notif->id,
                    'clave' => 'reporte_id',
                    'valor' => $reporte->id
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Reporte actualizado exitosamente',
                'data' => $reporte->load(['categoria', 'cuadrante', 'caracteristicas', 'imagenes'])
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error($e);
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar reporte: ' . $e->getMessage(),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }

    /**
     * Eliminar reporte
     */
    public function destroy($id)
    {
        try {
            $reporte = Reporte::findOrFail($id);
            $reporte->delete();

            return response()->json([
                'success' => true,
                'message' => 'Reporte eliminado exitosamente'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar reporte',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Subir imagen para un reporte
     */
    public function uploadImage(Request $request)
    {
        $validator = Validator::make($request->all(), [
            // Max 10MB
            'imagen' => 'required|image|max:10240',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $file = $request->file('imagen');
            $mimeType = $file->getMimeType();
            $base64 = base64_encode(file_get_contents($file->getRealPath()));

            $imagen = ImagenAlmacenada::create([
                'mime_type' => $mimeType,
                'base64_data' => $base64,
            ]);

            $url = url('/api/img/' . $imagen->id);

            return response()->json([
                'success' => true,
                'url' => $url,
                'path' => 'db:' . $imagen->id
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al subir la imagen',
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
            $reporte = Reporte::findOrFail($reporteId);
            $service = new \App\Services\ExpansionService();
            $success = $service->expandir($reporte);

            if (!$success) {
                return response()->json([
                    'success' => false,
                    'message' => 'No se pudo expandir el reporte en este momento. Verifique que el reporte esté activo y no haya alcanzado el nivel máximo.'
                ], 400);
            }

            return response()->json([
                'success' => true,
                'message' => 'Reporte expandido exitosamente al nivel ' . $reporte->nivel_expansion,
                'data' => [
                    'reporte' => $reporte->load('expansiones'),
                    'nuevo_nivel' => $reporte->nivel_expansion,
                    'proxima_expansion' => $reporte->proxima_expansion
                ]
            ], 200);

        } catch (\Exception $e) {
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
                'message' => 'Reporte expandido INMEDIATAMENTE (modo testing)',
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
     * Enviar mensaje masivo a todos los voluntarios activos de un reporte
     */
    public function broadcastMensaje(Request $request, $reporteId)
    {
        $validator = Validator::make($request->all(), [
            'mensaje' => 'required|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();

            $reporte = Reporte::findOrFail($reporteId);

            // Obtener voluntarios activos
            $voluntarios = \App\Models\ReporteVoluntario::where('reporte_id', $reporte->id)
                ->whereIn('estado', ['buscando', 'esperando'])
                ->get();
            
            $notificacionesCreadas = 0;

            foreach ($voluntarios as $voluntario) {
                // Evitar notificar al autor si también es voluntario
                if ($voluntario->usuario_id === $reporte->usuario_id) continue;
                
                $notif = \App\Models\Notificacion::create([
                    'usuario_id' => $voluntario->usuario_id,
                    'tipo' => 'alerta_operativo',
                    'titulo' => 'Alerta del Coordinador',
                    'mensaje' => $request->mensaje,
                    'leida' => false,
                    'enviada_push' => false,
                ]);
                
                \App\Models\NotificacionDato::create([
                    'notificacion_id' => $notif->id,
                    'clave' => 'reporte_id',
                    'valor' => $reporte->id
                ]);
                
                \App\Models\NotificacionDato::create([
                    'notificacion_id' => $notif->id,
                    'clave' => 'titulo_reporte',
                    'valor' => $reporte->titulo
                ]);
                
                $notificacionesCreadas++;
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Alerta enviada exitosamente al equipo',
                'voluntarios_notificados' => $notificacionesCreadas
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al enviar alerta',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Enviar mensaje directo a un voluntario específico
     */
    public function enviarMensajeVoluntario(Request $request, $reporteId, $usuarioId)
    {
        $validator = Validator::make($request->all(), [
            'mensaje' => 'required|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();

            $reporte = Reporte::findOrFail($reporteId);
            
            // Verificar que el usuario sea parte del reporte
            $vinculo = \App\Models\ReporteVoluntario::where('reporte_id', $reporte->id)
                ->where('usuario_id', $usuarioId)
                ->first();
                
            if (!$vinculo) {
                return response()->json([
                    'success' => false,
                    'message' => 'El usuario no está vinculado a este operativo'
                ], 404);
            }

            $notif = \App\Models\Notificacion::create([
                'usuario_id' => $usuarioId,
                'tipo' => 'mensaje_directo',
                'titulo' => 'Mensaje Directo (Coordinador)',
                'mensaje' => $request->mensaje,
                'leida' => false,
                'enviada_push' => false,
            ]);

            \App\Models\NotificacionDato::create([
                'notificacion_id' => $notif->id,
                'clave' => 'reporte_id',
                'valor' => $reporte->id
            ]);

            \App\Models\NotificacionDato::create([
                'notificacion_id' => $notif->id,
                'clave' => 'titulo_reporte',
                'valor' => $reporte->titulo
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Mensaje directo enviado exitosamente'
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al enviar mensaje directo',
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
     * Obtener Galería Centralizada del Reporte
     */
    public function obtenerGaleria($reporteId)
    {
        try {
            $reporte = Reporte::findOrFail($reporteId);
            $galeria = [];

            // 1. Imágenes originales del reporte
            $imagenesReporte = ReporteImagen::where('reporte_id', $reporteId)
                ->orderBy('created_at', 'asc')
                ->get();

            foreach ($imagenesReporte as $img) {
                $fixedUrl = str_replace('http://', 'https://', $img->url);
                
                $galeria[] = [
                    'id' => $img->id,
                    'url' => $fixedUrl,
                    'tipo' => 'original',
                    'autor' => 'Reporte original',
                    'fecha' => $img->created_at,
                    'aprobado' => true
                ];
            }

            // 2. Imágenes de pistas/respuestas aprobadas
            $respuestas = \App\Models\Respuesta::where('reporte_id', $reporteId)
                ->where('estado_evidencia', 'approved')
                ->with(['imagenes', 'usuario'])
                ->get();

            foreach ($respuestas as $respuesta) {
                // Si usan tabla RespuestaImagen (usando getRelation para evitar colisión con la columna 'imagenes')
                $imagenesRelacion = $respuesta->relationLoaded('imagenes') ? $respuesta->getRelation('imagenes') : collect();

                if ($imagenesRelacion instanceof \Illuminate\Database\Eloquent\Collection && $imagenesRelacion->isNotEmpty()) {
                    foreach ($imagenesRelacion as $img) {
                        $fixedUrl = str_replace('http://', 'https://', $img->url);
                        
                        $galeria[] = [
                            'id' => $img->id,
                            'url' => $fixedUrl,
                            'tipo' => 'evidencia',
                            'autor' => $respuesta->usuario ? $respuesta->usuario->nombre : 'Voluntario',
                            'fecha' => $img->created_at,
                            'aprobado' => true
                        ];
                    }
                } else {
                    // Fallback si usan el array JSON 'imagenes'
                    $urls = [];
                    if (is_array($respuesta->imagenes)) {
                        $urls = $respuesta->imagenes;
                    } elseif (is_string($respuesta->imagenes)) {
                        $decoded = json_decode($respuesta->imagenes, true);
                        if (is_array($decoded)) {
                            $urls = $decoded;
                        }
                    }
                    foreach ($urls as $idx => $url) {
                        if (is_string($url)) {
                            $fixedUrl = str_replace('http://', 'https://', $url);
                            
                            $galeria[] = [
                                'id' => $respuesta->id . '-' . $idx,
                                'url' => $fixedUrl,
                                'tipo' => 'evidencia',
                                'autor' => $respuesta->usuario ? $respuesta->usuario->nombre : 'Voluntario',
                                'fecha' => $respuesta->created_at,
                                'aprobado' => true
                            ];
                        }
                    }
                }
            }

            // Ordenar por fecha desc
            usort($galeria, function($a, $b) {
                $timeA = $a['fecha'] instanceof \Carbon\Carbon ? $a['fecha']->timestamp : strtotime($a['fecha']);
                $timeB = $b['fecha'] instanceof \Carbon\Carbon ? $b['fecha']->timestamp : strtotime($b['fecha']);
                return $timeB <=> $timeA;
            });

            return response()->json([
                'success' => true,
                'data' => $galeria
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al cargar la galería',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Listar Comentarios de un Reporte
     */
    public function listarComentarios($reporteId)
    {
        try {
            $comentarios = \App\Models\Comentario::where('reporte_id', $reporteId)
                ->with('usuario')
                ->orderBy('created_at', 'asc')
                ->get();
            return response()->json(['success' => true, 'data' => $comentarios], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Agregar Comentario a un Reporte
     */
    public function agregarComentario(Request $request, $reporteId)
    {
        $request->validate([
            'usuario_id' => 'required|exists:usuarios,id',
            'texto' => 'required|string'
        ]);

        try {
            $comentario = \App\Models\Comentario::create([
                'reporte_id' => $reporteId,
                'usuario_id' => $request->usuario_id,
                'texto' => $request->texto
            ]);

            return response()->json([
                'success' => true,
                'data' => $comentario->load('usuario')
            ], 201);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Mostrar reporte específico
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
    public function marcarResuelto(Request $request, $reporteId)
    {
        try {
            $reporte = Reporte::findOrFail($reporteId);

            $justificacion = $request->input('justificacion', null);

            $reporte->estado = 'resuelto';
            try {
                if (!empty($justificacion)) {
                    $reporte->justificacion = $justificacion;
                }
                $reporte->save();
            } catch (\Exception $saveEx) {
                unset($reporte->justificacion);
                $reporte->save();
            }

            // E14.3: Notificar a TODOS los voluntarios vinculados via push
            $this->notificarVoluntariosCambioEstado($reporte, 'positivo', $justificacion);

            return response()->json([
                'success' => true,
                'message' => 'Reporte marcado como resuelto',
                'data' => $reporte
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al marcar reporte como resuelto: ' . $e->getMessage(),
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Pausar reporte
     */
    public function pausar(Request $request, $reporteId)
    {
        try {
            $reporte = Reporte::findOrFail($reporteId);

            $justificacion = $request->input('justificacion', null);

            // Auto-patch the database constraint if it doesn't allow 'pausado'
            try {
                \Illuminate\Support\Facades\DB::statement("ALTER TABLE reportes DROP CONSTRAINT IF EXISTS check_estado");
                \Illuminate\Support\Facades\DB::statement("ALTER TABLE reportes ADD CONSTRAINT check_estado CHECK (estado IN ('activo', 'resuelto', 'inactivo', 'spam', 'pausado'))");
            } catch (\Exception $dbEx) {}

            $reporte->estado = 'pausado';
            try {
                if (!empty($justificacion)) {
                    $reporte->justificacion = $justificacion;
                }
                $reporte->save();
            } catch (\Exception $saveEx) {
                unset($reporte->justificacion);
                $reporte->save();
            }

            // E14.3: Notificar a TODOS los voluntarios vinculados via push
            $this->notificarVoluntariosCambioEstado($reporte, 'suspension', $justificacion);

            return response()->json([
                'success' => true,
                'message' => 'Reporte pausado',
                'data' => $reporte
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al pausar reporte: ' . $e->getMessage(),
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Reabrir reporte
     */
    public function reabrir($reporteId)
    {
        try {
            $reporte = Reporte::findOrFail($reporteId);

            try {
                $updateData = [
                    'estado' => 'activo',
                    'justificacion' => null
                ];
                
                if ($reporte->proxima_expansion && $reporte->proxima_expansion->isPast()) {
                    $updateData['proxima_expansion'] = now()->addMinutes(5);
                }
                
                $reporte->update($updateData);
            } catch (\Exception $saveEx) {
                $reporte->update([
                    'estado' => 'activo'
                ]);
            }

            // E14.3: Notificar a TODOS los voluntarios vinculados via push
            $this->notificarVoluntariosCambioEstado($reporte, 'reapertura');

            return response()->json([
                'success' => true,
                'message' => 'Reporte reabierto activamente',
                'data' => $reporte
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al reabrir reporte',
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

    /**
     * E14.3: Notificar a TODOS los voluntarios vinculados a un reporte
     * cuando cambia de estado (resuelto, pausado, reabierto).
     * Envia push via FCM y guarda la notificacion en la BD.
     */
    private function notificarVoluntariosCambioEstado($reporte, string $tipoResultado, ?string $justificacion = null)
    {
        try {
            // Obtener todos los voluntarios vinculados al reporte
            $voluntarios = \App\Models\ReporteVoluntario::where('reporte_id', $reporte->id)
                ->whereIn('estado', ['buscando', 'esperando', 'activo'])
                ->with('usuario')
                ->get();

            if ($voluntarios->isEmpty()) {
                \Log::channel('fcm')->info("[E14.3] No hay voluntarios vinculados al reporte {$reporte->id}");
                return;
            }

            // Obtener la plantilla de mensaje segun el tipo de resultado
            $nombreCreador = $reporte->usuario->nombre ?? '';

            switch ($tipoResultado) {
                case 'positivo':
                    $plantilla = NotificacionPlantillas::positivo($reporte->titulo, $nombreCreador);
                    break;
                case 'suspension':
                    $plantilla = NotificacionPlantillas::suspension($reporte->titulo, $justificacion ?? '');
                    break;
                case 'reapertura':
                    $plantilla = NotificacionPlantillas::reapertura($reporte->titulo);
                    break;
                default:
                    \Log::channel('fcm')->warning("[E14.3] Tipo de resultado desconocido: {$tipoResultado}");
                    return;
            }

            $fcm = new FcmService();
            $tokensParaPush = [];

            foreach ($voluntarios as $voluntario) {
                $usuario = $voluntario->usuario;
                if (!$usuario) continue;

                // No notificar al creador del reporte
                if ($usuario->id === $reporte->usuario_id) continue;

                // Guardar notificacion en la BD
                $notif = Notificacion::create([
                    'usuario_id' => $usuario->id,
                    'tipo' => $plantilla['tipo'],
                    'titulo' => $plantilla['titulo'],
                    'mensaje' => $plantilla['cuerpo'],
                    'leida' => false,
                    'enviada_push' => false,
                    'enviada_email' => false,
                ]);

                NotificacionDato::create([
                    'notificacion_id' => $notif->id,
                    'clave' => 'reporte_id',
                    'valor' => $reporte->id,
                ]);

                // Recopilar token FCM si el usuario lo tiene registrado
                if (!empty($usuario->fcm_token)) {
                    $tokensParaPush[] = [
                        'token' => $usuario->fcm_token,
                        'notif_id' => $notif->id,
                    ];
                }
            }

            // Enviar push masivo via FCM
            if ($fcm->estaConfigurado() && !empty($tokensParaPush)) {
                $enviados = 0;
                $fallidos = 0;
                foreach ($tokensParaPush as $item) {
                    $enviado = $fcm->enviarAToken(
                        $item['token'],
                        $plantilla['titulo'],
                        $plantilla['cuerpo'],
                        ['reporte_id' => $reporte->id, 'tipo' => $plantilla['tipo']]
                    );

                    // Marcar como enviada_push en la BD
                    if ($enviado) {
                        Notificacion::where('id', $item['notif_id'])->update(['enviada_push' => true]);
                        $enviados++;
                    } else {
                        $fallidos++;
                    }
                }

                \Log::channel('fcm')->info("[E14.3] Push enviado para reporte {$reporte->id}", [
                    'tipo_resultado' => $tipoResultado,
                    'total_voluntarios_vinculados' => $voluntarios->count(),
                    'con_token_fcm' => count($tokensParaPush),
                    'exitosos' => $enviados,
                    'fallidos' => $fallidos
                ]);
            } else {
                \Log::channel('fcm')->warning("[E14.3] No se enviaron push para reporte {$reporte->id}. Fcm configurado: " . ($fcm->estaConfigurado() ? 'Si' : 'No') . ", Tokens validos: " . count($tokensParaPush));
            }

        } catch (\Exception $e) {
            \Log::channel('fcm')->error("[E14.3] Error al notificar voluntarios: " . $e->getMessage());
        }
    }

    // =========================================================================
    // PISTAS DE BUSQUEDA
    // =========================================================================

    /**
     * Listar todas las pistas (respuestas tipo 'pista') de un reporte
     */
    public function listarPistas($reporteId)
    {
        try {
            $reporte = Reporte::findOrFail($reporteId);

            $pistas = \App\Models\Respuesta::where('reporte_id', $reporte->id)
                ->where('tipo_respuesta', 'informacion')
                ->whereNotNull('ubicacion_lat')
                ->whereNotNull('ubicacion_lng')
                ->orderBy('created_at')
                ->get();

            return response()->json([
                'success' => true,
                'data'    => $pistas,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener pistas',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Guardar una nueva pista de búsqueda desde la app móvil.
     * Solo el creador del reporte puede guardar pistas.
     */
    public function guardarPistaApi(Request $request, $reporteId)
    {
        try {
            $reporte = Reporte::findOrFail($reporteId);

            // ── Autorización: solo el creador ─────────────────────────────────
            $usuarioId = $request->input('usuario_id');
            if (!$usuarioId || $usuarioId !== $reporte->usuario_id) {
                return response()->json([
                    'success' => false,
                    'error'   => 'Solo el creador del operativo puede agregar pistas.',
                ], 403);
            }

            // ── Validación ────────────────────────────────────────────────────
            $validator = Validator::make($request->all(), [
                'lat'          => 'required|numeric|between:-90,90',
                'lng'          => 'required|numeric|between:-180,180',
                'etiqueta'     => 'required|string|max:100',
                'cuadrante_id' => 'nullable|exists:cuadrantes,id',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'errors'  => $validator->errors(),
                ], 422);
            }

            // ── Crear pista ───────────────────────────────────────────────────
            $pista = \App\Models\Respuesta::create([
                'reporte_id'           => $reporte->id,
                'cuadrante_id'         => $request->cuadrante_id,
                'usuario_id'           => $usuarioId,
                'tipo_respuesta'       => 'informacion',
                'mensaje'              => $request->etiqueta,
                'ubicacion_lat'        => $request->lat,
                'ubicacion_lng'        => $request->lng,
                'direccion_referencia' => $request->descripcion,
                'verificada'           => true,
            ]);

            return response()->json([
                'success' => true,
                'data'    => $pista,
                'message' => 'Pista registrada correctamente.',
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al guardar la pista',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Actualizar una pista de búsqueda existente
     */
    public function actualizarPistaApi(Request $request, $pistaId)
    {
        try {
            $pista = \App\Models\Respuesta::findOrFail($pistaId);
            
            // Validar que el usuario sea el dueño del reporte o admin
            // (Para simplificar en esta etapa, permitimos si el token es válido)
            
            $pista->update([
                'mensaje'              => $request->etiqueta ?? $pista->mensaje,
                'ubicacion_lat'        => $request->lat ?? $pista->ubicacion_lat,
                'ubicacion_lng'        => $request->lng ?? $pista->ubicacion_lng,
                'direccion_referencia' => $request->descripcion ?? $pista->direccion_referencia,
                'cuadrante_id'         => $request->cuadrante_id ?? $pista->cuadrante_id,
            ]);

            return response()->json([
                'success' => true,
                'data'    => $pista,
                'message' => 'Pista actualizada correctamente.',
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar la pista',
            ], 500);
        }
    }

    /**
     * Eliminar una pista de búsqueda
     */
    public function eliminarPistaApi($pistaId)
    {
        try {
            $pista = \App\Models\Respuesta::findOrFail($pistaId);
            $pista->delete();

            return response()->json([
                'success' => true,
                'message' => 'Pista eliminada correctamente.',
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar la pista',
            ], 500);
        }
    }

    // =========================================================================
    // E13.2 – REPORTE FINAL DE OPERATIVO (PDF)
    // =========================================================================

    /**
     * Generar datos consolidados del operativo para el reporte final PDF.
     *
     * Retorna en UNA sola llamada:
     *   - Ficha completa (categoria, cuadrante, características, imágenes)
     *   - Voluntarios que participaron con tiempo activo individual
     *   - Recorridos GPS de todos los voluntarios
     *   - Evidencias aprobadas (galería)
     *   - Estadísticas calculadas:
     *       * total_voluntarios, tiempo_total_minutos, tiempo_activo_minutos
     *       * distancia_total_km (suma Haversine de todos los recorridos)
     *       * cuadrantes_expandidos, evidencias aprobadas / rechazadas
     *
     * GET /api/reportes/{id}/reporte-final
     */
    public function reporteFinal($id)
    {
        try {
            // ── 1. Carga completa del reporte ────────────────────────────────
            $reporte = Reporte::with([
                'categoria',
                'usuario:id,nombre,avatar_url,telefono',
                'cuadrante',
                'caracteristicas',
                'imagenes',
                'expansiones.cuadranteExpandido',
            ])->findOrFail($id);

            // ── 2. Voluntarios con datos de tracking ─────────────────────────
            $voluntariosRaw = \App\Models\ReporteVoluntario::where('reporte_id', $id)
                ->with('usuario:id,nombre,avatar_url,telefono')
                ->get();

            $voluntariosData = $voluntariosRaw->map(function ($v) {
                $minutos = 0;
                if ($v->inicio_busqueda && $v->fin_busqueda) {
                    $inicio = \Carbon\Carbon::parse($v->inicio_busqueda);
                    $fin    = \Carbon\Carbon::parse($v->fin_busqueda);
                    $minutos = max(0, $inicio->diffInMinutes($fin));
                } elseif ($v->inicio_busqueda) {
                    // Aún buscando: calcular desde inicio hasta ahora
                    $inicio  = \Carbon\Carbon::parse($v->inicio_busqueda);
                    $minutos = max(0, $inicio->diffInMinutes(now()));
                }

                return [
                    'id'               => $v->id,
                    'usuario_id'       => $v->usuario_id,
                    'nombre'           => $v->usuario->nombre ?? 'Voluntario',
                    'avatar_url'       => $v->usuario->avatar_url ?? null,
                    'telefono'         => $v->usuario->telefono ?? null,
                    'estado'           => $v->estado,
                    'estado_busqueda'  => $v->estado_busqueda,
                    'inicio_busqueda'  => $v->inicio_busqueda,
                    'fin_busqueda'     => $v->fin_busqueda,
                    'tiempo_minutos'   => $minutos,
                    'tiene_vehiculo'   => $v->tiene_vehiculo,
                    'tipo_vehiculo'    => $v->tipo_vehiculo,
                ];
            });

            // ── 3. Recorridos GPS (sólo los que tienen puntos) ───────────────
            $recorridosRaw = \App\Models\ReporteVoluntario::where('reporte_id', $id)
                ->whereNotNull('recorrido_puntos')
                ->with('usuario:id,nombre')
                ->get();

            $recorridos = $recorridosRaw->map(fn($v) => [
                'usuario_id'      => $v->usuario_id,
                'nombre'          => $v->usuario->nombre ?? 'Voluntario',
                'estado_busqueda' => $v->estado_busqueda,
                'inicio_busqueda' => $v->inicio_busqueda,
                'fin_busqueda'    => $v->fin_busqueda,
                'puntos'          => is_string($v->recorrido_puntos)
                    ? json_decode($v->recorrido_puntos, true)
                    : ($v->recorrido_puntos ?? []),
            ]);

            // ── 4. Evidencias aprobadas / rechazadas ─────────────────────────
            $evidenciasRaw = \App\Models\Respuesta::where('reporte_id', $id)
                ->with(['usuario:id,nombre', 'imagenes'])
                ->get();

            $evidencias = collect();
            foreach ($evidenciasRaw as $respuesta) {
                $estado = $respuesta->estado_evidencia ?? 'pending';
                $imagenesRelacion = $respuesta->relationLoaded('imagenes')
                    ? $respuesta->getRelation('imagenes')
                    : collect();

                if ($imagenesRelacion instanceof \Illuminate\Database\Eloquent\Collection && $imagenesRelacion->isNotEmpty()) {
                    foreach ($imagenesRelacion as $img) {
                        $evidencias->push([
                            'id'          => $img->id,
                            'foto_url'    => str_replace('http://', 'https://', $img->url),
                            'descripcion' => $respuesta->mensaje ?? '',
                            'estado'      => $estado,
                            'autor'       => $respuesta->usuario->nombre ?? 'Voluntario',
                            'lat'         => $respuesta->ubicacion_lat,
                            'lng'         => $respuesta->ubicacion_lng,
                            'created_at'  => $respuesta->created_at,
                        ]);
                    }
                } else {
                    // Fallback para imagenes en JSON
                    $urls = [];
                    if (is_array($respuesta->imagenes)) {
                        $urls = $respuesta->imagenes;
                    } elseif (is_string($respuesta->imagenes)) {
                        $urls = json_decode($respuesta->imagenes, true) ?? [];
                    }
                    foreach ($urls as $url) {
                        if (is_string($url)) {
                            $evidencias->push([
                                'id'          => $respuesta->id,
                                'foto_url'    => str_replace('http://', 'https://', $url),
                                'descripcion' => $respuesta->mensaje ?? '',
                                'estado'      => $estado,
                                'autor'       => $respuesta->usuario->nombre ?? 'Voluntario',
                                'lat'         => $respuesta->ubicacion_lat,
                                'lng'         => $respuesta->ubicacion_lng,
                                'created_at'  => $respuesta->created_at,
                            ]);
                        }
                    }
                }
            }

            // ── 5. Calcular estadísticas ─────────────────────────────────────

            // 5a. Tiempo total del operativo (created_at → ahora o updated_at si resuelto)
            $fechaInicio = $reporte->created_at;
            $fechaFin    = in_array($reporte->estado, ['resuelto', 'terminado', 'cerrado'])
                ? $reporte->updated_at
                : now();
            $tiempoTotalMinutos = max(0, $fechaInicio->diffInMinutes($fechaFin));

            // 5b. Tiempo activo acumulado de todos los voluntarios
            $tiempoActivoMinutos = $voluntariosData->sum('tiempo_minutos');

            // 5c. Distancia total cubierta (Haversine sobre todos los recorridos)
            $distanciaTotalKm = 0.0;
            foreach ($recorridos as $recorrido) {
                $puntos = $recorrido['puntos'];
                if (!is_array($puntos) || count($puntos) < 2) continue;
                for ($i = 1; $i < count($puntos); $i++) {
                    $distanciaTotalKm += $this->haversineKm(
                        (float)$puntos[$i - 1]['lat'],
                        (float)$puntos[$i - 1]['lng'],
                        (float)$puntos[$i]['lat'],
                        (float)$puntos[$i]['lng']
                    );
                }
            }

            // 5d. Cuadrantes expandidos
            $cuadrantesExpandidos = $reporte->expansiones->pluck('cuadrante_expandido_id')->unique()->count();
            $cuadrantesExpandidos = max(1, $cuadrantesExpandidos); // Mínimo 1 (el original)

            // 5e. Contadores de evidencias
            $totalEvidencias      = $evidencias->count();
            $evidenciasAprobadas  = $evidencias->where('estado', 'approved')->count();
            $evidenciasRechazadas = $evidencias->where('estado', 'rejected')->count();

            // ── 6. Construir primera imagen ──────────────────────────────────
            $primeraImagen = null;
            if ($reporte->imagenes->isNotEmpty()) {
                $url = $reporte->imagenes->first()->url;
                $primeraImagen = str_replace('http://', 'https://', $url);
            }

            // ── 7. Construir respuesta consolidada ───────────────────────────
            $data = [
                // Ficha
                'id'                  => $reporte->id,
                'titulo'              => $reporte->titulo,
                'descripcion'         => $reporte->descripcion,
                'estado'              => $reporte->estado,
                'prioridad'           => $reporte->prioridad,
                'categoria'           => $reporte->categoria->nombre ?? null,
                'categoria_id'        => $reporte->categoria_id,
                'fecha_reporte'       => $reporte->created_at,
                'fecha_perdida'       => $reporte->fecha_perdida,
                'fecha_resolucion'    => in_array($reporte->estado, ['resuelto', 'terminado', 'cerrado'])
                    ? $reporte->updated_at
                    : null,
                'justificacion'       => $reporte->justificacion,
                'cuadrante_nombre'    => $reporte->cuadrante->nombre ?? null,
                'cuadrante_zona'      => $reporte->cuadrante->zona ?? null,
                'latitud'             => $reporte->ubicacion_exacta_lat,
                'longitud'            => $reporte->ubicacion_exacta_lng,
                'direccion_referencia' => $reporte->direccion_referencia,
                'telefono_contacto'   => $reporte->telefono_contacto,
                'email_contacto'      => $reporte->email_contacto,
                'recompensa'          => $reporte->recompensa,
                'nivel_expansion'     => $reporte->nivel_expansion,
                'max_expansion'       => $reporte->max_expansion,
                'vistas'              => $reporte->vistas,
                'primera_imagen'      => $primeraImagen,

                // Autor
                'creador' => [
                    'nombre'     => $reporte->usuario->nombre ?? null,
                    'avatar_url' => $reporte->usuario->avatar_url ?? null,
                    'telefono'   => $reporte->usuario->telefono ?? null,
                ],

                // Características
                'caracteristicas' => $reporte->caracteristicas->pluck('valor', 'clave'),

                // Cuadrantes expandidos (lista)
                'expansiones' => $reporte->expansiones->map(fn($e) => [
                    'cuadrante_id'   => $e->cuadrante_expandido_id,
                    'nombre'         => $e->cuadranteExpandido->nombre ?? null,
                    'nivel'          => $e->nivel,
                    'fecha'          => $e->fecha_expansion,
                ]),

                // Voluntarios
                'voluntarios' => $voluntariosData,

                // Recorridos GPS
                'recorridos' => $recorridos,

                // Evidencias (todas, con estado)
                'evidencias' => $evidencias->values(),

                // Estadísticas calculadas
                'estadisticas' => [
                    'total_voluntarios'       => $voluntariosData->count(),
                    'tiempo_total_minutos'    => (int) $tiempoTotalMinutos,
                    'tiempo_activo_minutos'   => (int) $tiempoActivoMinutos,
                    'distancia_total_km'      => round($distanciaTotalKm, 3),
                    'cuadrantes_expandidos'   => $cuadrantesExpandidos,
                    'total_evidencias'        => $totalEvidencias,
                    'evidencias_aprobadas'    => $evidenciasAprobadas,
                    'evidencias_rechazadas'   => $evidenciasRechazadas,
                    'vistas'                  => $reporte->vistas,
                ],
            ];

            return response()->json([
                'success' => true,
                'data'    => $data,
            ], 200);

        } catch (\Exception $e) {
            \Log::error('[E13.2] Error al generar reporte final: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al generar el reporte final del operativo',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Calcular distancia entre dos coordenadas usando la fórmula de Haversine.
     * Retorna la distancia en kilómetros.
     */
    private function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $radioTierra = 6371.0; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $radioTierra * $c;
    }
}

