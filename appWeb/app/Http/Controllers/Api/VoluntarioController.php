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
            'usuario_id' => 'required|exists:usuarios,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $reporte = Reporte::findOrFail($reporteId);
            
            // Verificar si ya está vinculado
            $voluntarioExistente = ReporteVoluntario::where('reporte_id', $reporteId)
                ->where('usuario_id', $request->usuario_id)
                ->first();

            if ($voluntarioExistente) {
                // Si estaba inactivo temporalmente, lo reactivamos
                if ($voluntarioExistente->estado !== 'buscando') {
                    $voluntarioExistente->estado = 'buscando';
                    $voluntarioExistente->save();
                }
                return response()->json([
                    'success' => true,
                    'message' => 'El usuario ya estaba vinculado, se reactivó su estado',
                    'data' => $voluntarioExistente
                ], 200);
            }

            $voluntario = ReporteVoluntario::create([
                'reporte_id' => $reporteId,
                'usuario_id' => $request->usuario_id,
                'estado' => 'buscando',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Te has unido a la búsqueda exitosamente',
                'data' => $voluntario->load('usuario')
            ], 201);
            
        } catch (\Exception $e) {
            Log::error('Error al unirse a búsqueda: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al unirse a la búsqueda',
                'error' => $e->getMessage()
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
                ->firstOrFail();

            $voluntario->estado_busqueda = 'terminado';
            $voluntario->fin_busqueda = now();
            $voluntario->recorrido_puntos = $request->puntos;
            $voluntario->save();

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
}
