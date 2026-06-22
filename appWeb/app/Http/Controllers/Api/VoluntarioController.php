<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReporteVoluntario;
use App\Models\Reporte;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class VoluntarioController extends Controller
{
    /**
     * Unirse a un reporte como voluntario
     */
    public function unirse(Request $request, $reporteId)
    {
        $validator = Validator::make($request->all(), [
            'usuario_id'           => 'required|exists:usuarios,id',
            // Campos opcionales de metadata del voluntario
            'habilidades_ofrecidas' => 'sometimes|array',
            'habilidades_ofrecidas.*' => 'string|max:100',
            'tiene_vehiculo'       => 'sometimes|boolean',
            'tipo_vehiculo'        => 'sometimes|nullable|string|max:100',
            'disponibilidad_horas' => 'sometimes|nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $reporte = Reporte::findOrFail($reporteId);

            // Verificar si ya está vinculado
            $voluntarioExistente = ReporteVoluntario::where('reporte_id', $reporteId)
                ->where('usuario_id', $request->usuario_id)
                ->first();

            if ($voluntarioExistente) {
                // Si estaba inactivo temporalmente, lo reactivamos y actualizamos metadata
                if ($voluntarioExistente->estado !== 'buscando') {
                    $voluntarioExistente->estado = 'buscando';
                }
                // Actualizar metadata si se envió
                if ($request->has('habilidades_ofrecidas')) {
                    $voluntarioExistente->habilidades_ofrecidas = $request->habilidades_ofrecidas;
                }
                if ($request->has('tiene_vehiculo')) {
                    $voluntarioExistente->tiene_vehiculo = $request->tiene_vehiculo;
                }
                if ($request->has('tipo_vehiculo')) {
                    $voluntarioExistente->tipo_vehiculo = $request->tipo_vehiculo;
                }
                if ($request->has('disponibilidad_horas')) {
                    $voluntarioExistente->disponibilidad_horas = $request->disponibilidad_horas;
                }
                $voluntarioExistente->save();

                return response()->json([
                    'success' => true,
                    'message' => 'El usuario ya estaba vinculado, se reactivó su estado',
                    'data'    => $voluntarioExistente
                ], 200);
            }

            $voluntario = ReporteVoluntario::create([
                'reporte_id'            => $reporteId,
                'usuario_id'            => $request->usuario_id,
                'estado'                => 'buscando',
                'habilidades_ofrecidas' => $request->input('habilidades_ofrecidas'),
                'tiene_vehiculo'        => $request->input('tiene_vehiculo', false),
                'tipo_vehiculo'         => $request->input('tipo_vehiculo'),
                'disponibilidad_horas'  => $request->input('disponibilidad_horas'),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Te has unido a la búsqueda exitosamente',
                'data'    => $voluntario->load('usuario')
            ], 201);

        } catch (\Exception $e) {
            Log::error('Error al unirse a búsqueda: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al unirse a la búsqueda',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Comprobar si un usuario ya es voluntario
     */
    public function verificarVinculo($reporteId, $usuarioId)
    {
        try {
            $vinculo = ReporteVoluntario::where('reporte_id', $reporteId)
                ->where('usuario_id', $usuarioId)
                ->first();

            return response()->json([
                'success' => true,
                'vinculado' => $vinculo !== null,
                'data' => $vinculo
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al verificar vínculo',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener todos los voluntarios de un reporte
     */
    public function listarPorReporte($reporteId)
    {
        try {
            $voluntarios = ReporteVoluntario::where('reporte_id', $reporteId)
                ->with('usuario')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $voluntarios,
                'count' => $voluntarios->count()
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener lista de voluntarios',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Abandonar la búsqueda explícitamente (marcar inactivo)
     */
    public function abandonar($reporteId, $usuarioId)
    {
        try {
            $voluntario = ReporteVoluntario::where('reporte_id', $reporteId)
                ->where('usuario_id', $usuarioId)
                ->firstOrFail();

            $voluntario->estado = 'inactivo';
            $voluntario->save();

            return response()->json([
                'success' => true,
                'message' => 'Has abandonado la búsqueda'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al abandonar búsqueda',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Iniciar sesión de búsqueda (tracking activo)
     */
    public function iniciarBusqueda(Request $request, $reporteId, $usuarioId)
    {
        try {
            $voluntario = ReporteVoluntario::where('reporte_id', $reporteId)
                ->where('usuario_id', $usuarioId)
                ->firstOrFail();

            if ($voluntario->estado_busqueda === 'activo') {
                return response()->json([
                    'success' => true,
                    'message' => 'La búsqueda ya está en curso',
                    'data' => $voluntario
                ], 200);
            }

            $voluntario->estado_busqueda = 'activo';
            $voluntario->inicio_busqueda = now();
            $voluntario->fin_busqueda = null;
            $voluntario->recorrido_puntos = null;
            $voluntario->save();

            return response()->json([
                'success' => true,
                'message' => 'Búsqueda iniciada. ¡Buena suerte!',
                'data' => $voluntario
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al iniciar búsqueda: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Pausar sesión de búsqueda
     */
    public function pausarBusqueda($reporteId, $usuarioId)
    {
        try {
            $voluntario = ReporteVoluntario::where('reporte_id', $reporteId)
                ->where('usuario_id', $usuarioId)
                ->firstOrFail();

            $voluntario->estado_busqueda = 'en_pausa';
            $voluntario->save();

            return response()->json([
                'success' => true,
                'message' => 'Búsqueda pausada',
                'data' => $voluntario
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al pausar búsqueda: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Terminar sesión de búsqueda y guardar recorrido completo
     */
    public function terminarBusqueda(Request $request, $reporteId, $usuarioId)
    {
        $validator = Validator::make($request->all(), [
            'puntos' => 'sometimes|array',
            'puntos.*.lat' => 'required|numeric|between:-90,90',
            'puntos.*.lng' => 'required|numeric|between:-180,180',
            'puntos.*.ts' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $voluntario = ReporteVoluntario::where('reporte_id', $reporteId)
                ->where('usuario_id', $usuarioId)
                ->firstOrFail();

            $puntosActuales = is_string($voluntario->recorrido_puntos) 
                ? json_decode($voluntario->recorrido_puntos, true) 
                : ($voluntario->recorrido_puntos ?? []);
                
            $nuevosPuntos = $request->input('puntos', []);
            $puntosFinales = array_merge($puntosActuales, $nuevosPuntos);

            $voluntario->estado_busqueda = 'terminado';
            $voluntario->fin_busqueda = now();
            $voluntario->recorrido_puntos = empty($puntosFinales) ? null : $puntosFinales;
            $voluntario->save();

            // Lógica de gamificación: 1 punto por cada 1km caminado
            $puntosGanados = 0;
            $distanciaKm = 0;
            if (count($puntosFinales) >= 2) {
                // Calcular distancia total
                for ($i = 1; $i < count($puntosFinales); $i++) {
                    $lat1 = floatval($puntosFinales[$i - 1]['lat']);
                    $lng1 = floatval($puntosFinales[$i - 1]['lng']);
                    $lat2 = floatval($puntosFinales[$i]['lat']);
                    $lng2 = floatval($puntosFinales[$i]['lng']);

                    $r = 6371; // Radio de la tierra en km
                    $dLat = deg2rad($lat2 - $lat1);
                    $dLon = deg2rad($lng2 - $lng1);
                    $a = sin($dLat/2) * sin($dLat/2) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon/2) * sin($dLon/2);
                    $c = 2 * atan2(sqrt($a), sqrt(1-$a));
                    $distanciaKm += $r * $c;
                }
            }

            $puntosGanados = floor($distanciaKm);

            // Solo dar puntos si caminó al menos 1 km y no es el dueño
            if ($puntosGanados > 0) {
                $reporte = Reporte::find($reporteId);
                if ($reporte && $reporte->usuario_id !== $usuarioId) {
                    $userToReward = \App\Models\Usuario::find($usuarioId);
                    if ($userToReward) {
                        $userToReward->increment('evidencias_plata_bronce', $puntosGanados);
                    }
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Búsqueda terminada. Recorrido guardado.',
                'data' => $voluntario
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al terminar búsqueda: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Obtener todos los recorridos completados de un reporte para mostrar en el mapa
     */
    public function obtenerRecorridos($reporteId)
    {
        try {
            $recorridos = ReporteVoluntario::where('reporte_id', $reporteId)
                ->whereIn('estado_busqueda', ['terminado', 'activo', 'en_pausa'])
                ->whereNotNull('recorrido_puntos')
                ->with('usuario:id,nombre,avatar_url')
                ->get()
                ->map(fn($v) => [
                    'voluntario_id' => $v->id,
                    'usuario' => $v->usuario,
                    'estado_busqueda' => $v->estado_busqueda,
                    'inicio_busqueda' => $v->inicio_busqueda,
                    'fin_busqueda' => $v->fin_busqueda,
                    'puntos' => $v->recorrido_puntos,
                ]);

            return response()->json([
                'success' => true,
                'data' => $recorridos
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener recorridos: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Sincronizar recorrido de búsqueda por ráfagas (Batches)
     */
    public function sincronizarRecorrido(Request $request, $reporteId, $usuarioId)
    {
        $validator = Validator::make($request->all(), [
            'puntos' => 'required|array|min:1',
            'puntos.*.lat' => 'required|numeric|between:-90,90',
            'puntos.*.lng' => 'required|numeric|between:-180,180',
            'puntos.*.ts' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $voluntario = ReporteVoluntario::where('reporte_id', $reporteId)
                ->where('usuario_id', $usuarioId)
                ->whereIn('estado_busqueda', ['activo', 'en_pausa'])
                ->first();

            // Si no existe sesión activa, ignorar silenciosamente (timer residual)
            if (!$voluntario) {
                return response()->json([
                    'success' => true,
                    'message' => 'Sin sesión activa, puntos descartados',
                    'puntos_totales' => 0
                ], 200);
            }

            $puntosActuales = is_string($voluntario->recorrido_puntos) 
                ? json_decode($voluntario->recorrido_puntos, true) 
                : ($voluntario->recorrido_puntos ?? []);

            $nuevosPuntos = $request->input('puntos', []);
            $puntosCombinados = array_merge($puntosActuales, $nuevosPuntos);

            $voluntario->recorrido_puntos = $puntosCombinados;
            
            if (!empty($nuevosPuntos)) {
                $ultimoPunto = end($nuevosPuntos);
                $voluntario->ultima_coordenada_lat = $ultimoPunto['lat'];
                $voluntario->ultima_coordenada_lng = $ultimoPunto['lng'];
                $voluntario->ultima_actualizacion_gps = now();
            }

            $voluntario->save();

            return response()->json([
                'success' => true,
                'message' => 'Recorrido sincronizado correctamente',
                'puntos_totales' => count($puntosCombinados)
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al sincronizar recorrido: ' . $e->getMessage(),
            ], 500);
        }
    }
}
