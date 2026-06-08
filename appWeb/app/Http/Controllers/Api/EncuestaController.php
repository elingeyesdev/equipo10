<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReporteVoluntario;
use App\Models\EncuestaSatisfaccion;
use App\Models\Reporte;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EncuestaController extends Controller
{
    /**
     * Obtener los operativos resueltos en los que el usuario participó
     * y aún no ha evaluado.
     */
    public function encuestasPendientes($usuarioId)
    {
        // Buscar los reportes donde el usuario fue voluntario
        $reportesParticipados = ReporteVoluntario::where('usuario_id', $usuarioId)
            ->pluck('reporte_id');

        if ($reportesParticipados->isEmpty()) {
            return response()->json([]);
        }

        // Obtener los IDs de reportes que ya evaluó
        $reportesEvaluados = EncuestaSatisfaccion::where('usuario_id', $usuarioId)
            ->pluck('reporte_id');

        // Filtrar los reportes que están cerrados/resueltos/terminados y no han sido evaluados
        $pendientes = Reporte::whereIn('id', $reportesParticipados)
            ->whereNotIn('id', $reportesEvaluados)
            ->whereIn('estado', ['resuelto', 'cerrado', 'terminado', 'inactivo'])
            ->get(['id', 'titulo', 'tipo_reporte', 'fecha_reporte', 'estado']);

        return response()->json($pendientes);
    }

    /**
     * Guardar una nueva encuesta de satisfacción.
     */
    public function store(Request $request)
    {
        $request->validate([
            'reporte_id' => 'required|uuid|exists:reportes,id',
            'usuario_id' => 'required|uuid|exists:usuarios,id',
            'puntuacion' => 'required|integer|min:1|max:5',
            'comentario' => 'nullable|string',
        ]);

        try {
            $encuesta = EncuestaSatisfaccion::create([
                'reporte_id' => $request->reporte_id,
                'usuario_id' => $request->usuario_id,
                'puntuacion' => $request->puntuacion,
                'comentario' => $request->comentario,
            ]);

            return response()->json([
                'message' => 'Encuesta guardada con éxito',
                'data' => $encuesta
            ], 201);

        } catch (\Exception $e) {
            // Verificar si es error por registro duplicado
            if ($e->getCode() == 23505) { // Unique violation Postgres
                return response()->json([
                    'message' => 'Ya has evaluado este operativo anteriormente.'
                ], 409);
            }

            return response()->json([
                'message' => 'Error al guardar la encuesta',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
