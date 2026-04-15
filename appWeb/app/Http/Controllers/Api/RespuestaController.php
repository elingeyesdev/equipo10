<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Respuesta;
use App\Models\Reporte;
use App\Models\Notificacion;
use App\Models\NotificacionDato;
use App\Models\RespuestaImagen;
use App\Models\RespuestaVideo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class RespuestaController extends Controller
{
    /**
     * Crear respuesta a un reporte
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'reporte_id' => 'required|exists:reportes,id',
            'usuario_id' => 'required|exists:usuarios,id',
            'tipo_respuesta' => 'required|in:avistamiento,encontrado,informacion,pregunta',
            'mensaje' => 'required|string',
            'ubicacion_lat' => 'nullable|numeric|between:-90,90',
            'ubicacion_lng' => 'nullable|numeric|between:-180,180',
            'direccion_referencia' => 'nullable|string',
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

            // Validar que si es tipo "encontrado" debe tener ubicación
            if ($request->tipo_respuesta === 'encontrado') {
                if (!$request->ubicacion_lat || !$request->ubicacion_lng) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Para tipo "encontrado" es obligatorio proporcionar la ubicación'
                    ], 422);
                }
            }

            // Validar que solo "encontrado" o "avistamiento" puedan tener multimedia
            if (in_array($request->tipo_respuesta, ['encontrado', 'avistamiento'])) {
                // Permitir imágenes y videos
            } else {
                // Para "informacion" y "pregunta" no se permiten multimedia
                if ($request->has('imagenes') || $request->has('videos')) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Solo las respuestas de tipo "encontrado" o "avistamiento" pueden incluir imágenes o videos'
                    ], 422);
                }
            }

            $reporte = Reporte::findOrFail($request->reporte_id);

            // Verificar que el reporte esté activo
            if ($reporte->estado !== 'activo') {
                return response()->json([
                    'success' => false,
                    'message' => 'No se puede responder a un reporte que no está activo'
                ], 400);
            }

            // Crear respuesta
            $respuesta = Respuesta::create([
                'reporte_id' => $request->reporte_id,
                'usuario_id' => $request->usuario_id,
                'tipo_respuesta' => $request->tipo_respuesta,
                'mensaje' => $request->mensaje,
                'ubicacion_lat' => $request->ubicacion_lat,
                'ubicacion_lng' => $request->ubicacion_lng,
                'direccion_referencia' => $request->direccion_referencia,
                'verificada' => false,
                'util' => null
            ]);

            // Agregar imágenes si existen
            if ($request->has('imagenes') && is_array($request->imagenes)) {
                foreach ($request->imagenes as $index => $url) {
                    RespuestaImagen::create([
                        'respuesta_id' => $respuesta->id,
                        'url' => $url,
                        'orden' => $index + 1
                    ]);
                }
            }

            // Agregar videos si existen
            if ($request->has('videos') && is_array($request->videos)) {
                foreach ($request->videos as $index => $url) {
                    RespuestaVideo::create([
                        'respuesta_id' => $respuesta->id,
                        'url' => $url,
                        'orden' => $index + 1
                    ]);
                }
            }

            // Notificar al creador del reporte
            $this->notificarCreadorReporte($reporte, $respuesta);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Respuesta creada exitosamente',
                'data' => $respuesta->load(['usuario', 'reporte', 'imagenes', 'videos'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al crear respuesta',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marcar respuesta como BIEN (verificada)
     */
    public function marcarBien($respuestaId)
    {
        try {
            DB::beginTransaction();

            $respuesta = Respuesta::with('reporte')->findOrFail($respuestaId);

            // Validar que sea tipo "encontrado"
            if ($respuesta->tipo_respuesta !== 'encontrado') {
                return response()->json([
                    'success' => false,
                    'message' => 'Solo se pueden marcar como BIEN las respuestas de tipo "encontrado"'
                ], 400);
            }

            // Marcar respuesta como verificada
            $respuesta->update([
                'verificada' => true,
                'util' => true
            ]);

            // Cambiar estado del reporte a resuelto
            $respuesta->reporte->update([
                'estado' => 'resuelto'
            ]);

            // Incrementar puntos del usuario que respondió
            $respuesta->usuario->increment('puntos_ayuda', 10);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Respuesta marcada como BIEN y reporte resuelto',
                'data' => [
                    'respuesta' => $respuesta,
                    'reporte' => $respuesta->reporte
                ]
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al marcar respuesta',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marcar respuesta como ERRÓNEO
     */
    public function marcarErroneo($respuestaId)
    {
        try {
            $respuesta = Respuesta::findOrFail($respuestaId);

            // Validar que sea tipo "encontrado"
            if ($respuesta->tipo_respuesta !== 'encontrado') {
                return response()->json([
                    'success' => false,
                    'message' => 'Solo se pueden marcar como ERRÓNEO las respuestas de tipo "encontrado"'
                ], 400);
            }

            // Marcar respuesta como no útil
            $respuesta->update([
                'verificada' => false,
                'util' => false
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Respuesta marcada como ERRÓNEO',
                'data' => $respuesta
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al marcar respuesta',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener respuestas de un reporte
     */
    public function respuestasDelReporte($reporteId)
    {
        try {
            $reporte = Reporte::findOrFail($reporteId);

            $respuestas = Respuesta::where('reporte_id', $reporteId)
                ->with(['usuario', 'imagenes', 'videos'])
                ->orderBy('created_at', 'desc')
                ->get();

            // Agrupar por tipo de respuesta
            $agrupadas = [
                'encontrado' => $respuestas->where('tipo_respuesta', 'encontrado')->values(),
                'avistamiento' => $respuestas->where('tipo_respuesta', 'avistamiento')->values(),
                'informacion' => $respuestas->where('tipo_respuesta', 'informacion')->values(),
                'pregunta' => $respuestas->where('tipo_respuesta', 'pregunta')->values()
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'reporte' => $reporte,
                    'respuestas' => $respuestas,
                    'respuestas_agrupadas' => $agrupadas,
                    'total' => $respuestas->count()
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener respuestas',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener respuestas tipo "encontrado" de un reporte
     */
    public function respuestasEncontrado($reporteId)
    {
        try {
            $respuestas = Respuesta::where('reporte_id', $reporteId)
                ->where('tipo_respuesta', 'encontrado')
                ->where(function($query) {
                    $query->where('util', '!=', false)
                        ->orWhereNull('util');
                })
                ->with(['usuario', 'imagenes', 'videos'])
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'respuestas' => $respuestas,
                    'total' => $respuestas->count()
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener respuestas',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener una respuesta específica
     */
    public function show($id)
    {
        try {
            $respuesta = Respuesta::with([
                'usuario',
                'reporte',
                'imagenes',
                'videos'
            ])->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => $respuesta
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Respuesta no encontrada',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Eliminar respuesta
     */
    public function destroy($id)
    {
        try {
            $respuesta = Respuesta::findOrFail($id);
            $respuesta->delete();

            return response()->json([
                'success' => true,
                'message' => 'Respuesta eliminada exitosamente'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar respuesta',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Notificar al creador del reporte sobre nueva respuesta
     */
    private function notificarCreadorReporte($reporte, $respuesta)
    {
        $tipoMensaje = [
            'avistamiento' => 'Alguien reportó un avistamiento',
            'encontrado' => '¡Alguien encontró tu objeto!',
            'informacion' => 'Alguien tiene información',
            'pregunta' => 'Alguien hizo una pregunta'
        ];

        $notificacion = Notificacion::create([
            'usuario_id' => $reporte->usuario_id,
            'tipo' => 'respuesta_reporte',
            'titulo' => $tipoMensaje[$respuesta->tipo_respuesta] ?? 'Nueva respuesta',
            'mensaje' => "Han respondido a tu reporte: {$reporte->titulo}",
            'leida' => false,
            'enviada_push' => false,
            'enviada_email' => false
        ]);

        NotificacionDato::create([
            'notificacion_id' => $notificacion->id,
            'clave' => 'reporte_id',
            'valor' => $reporte->id
        ]);

        NotificacionDato::create([
            'notificacion_id' => $notificacion->id,
            'clave' => 'respuesta_id',
            'valor' => $respuesta->id
        ]);

        NotificacionDato::create([
            'notificacion_id' => $notificacion->id,
            'clave' => 'tipo_respuesta',
            'valor' => $respuesta->tipo_respuesta
        ]);
    }
}

