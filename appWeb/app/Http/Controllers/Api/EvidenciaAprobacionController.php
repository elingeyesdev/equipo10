<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Respuesta;
use App\Models\Notificacion;
use Illuminate\Http\Request;

class EvidenciaAprobacionController extends Controller
{
    // Listar evidencias pendientes de aprobacion para un reporte
    public function pending($reporteId)
    {
        $evidencias = Respuesta::where('reporte_id', $reporteId)
            ->where('tipo_respuesta', 'avistamiento')
            ->where('estado_evidencia', 'pending')
            ->with(['usuario', 'imagenes'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $evidencias
        ], 200);
    }

    // Aprobar una evidencia (respuesta de avistamiento)
    public function approve($id)
    {
        $respuesta = Respuesta::with(['reporte'])->findOrFail($id);
        $respuesta->estado_evidencia = 'approved';
        $respuesta->save();

        // Notificar al creador del reporte
        Notificacion::create([
            'usuario_id' => $respuesta->reporte->usuario_id,
            'tipo' => 'evidencia_aprobada',
            'titulo' => 'Evidencia aprobada',
            'mensaje' => 'Aprobaste una evidencia en tu reporte: ' . $respuesta->reporte->titulo,
            'leida' => false,
            'enviada_push' => false,
            'enviada_email' => false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Evidencia aprobada',
            'data' => $respuesta
        ], 200);
    }

    // Rechazar una evidencia (respuesta de avistamiento)
    public function reject($id)
    {
        $respuesta = Respuesta::with(['reporte'])->findOrFail($id);
        $respuesta->estado_evidencia = 'rejected';
        $respuesta->save();

        Notificacion::create([
            'usuario_id' => $respuesta->reporte->usuario_id,
            'tipo' => 'evidencia_rechazada',
            'titulo' => 'Evidencia rechazada',
            'mensaje' => 'Rechazaste una evidencia en tu reporte: ' . $respuesta->reporte->titulo,
            'leida' => false,
            'enviada_push' => false,
            'enviada_email' => false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Evidencia rechazada',
            'data' => $respuesta
        ], 200);
    }
}
