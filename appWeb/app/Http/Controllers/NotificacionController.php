<?php

namespace App\Http\Controllers;

use App\Models\Notificacion;
use App\Models\Usuario;
use Illuminate\Http\Request;

class NotificacionController extends Controller
{
    public function index($usuarioId)
    {
        $notificaciones = Notificacion::where('usuario_id', $usuarioId)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $notificaciones
        ]);
    }

    public function noLeidas($usuarioId)
    {
        $notificaciones = Notificacion::where('usuario_id', $usuarioId)
            ->where('leida', false)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'count' => $notificaciones->count(),
            'data' => $notificaciones
        ]);
    }

    public function marcarTodasLeidas($usuarioId)
    {
        Notificacion::where('usuario_id', $usuarioId)
            ->where('leida', false)
            ->update(['leida' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Todas las notificaciones marcadas como leídas'
        ]);
    }

    public function eliminarTodas($usuarioId)
    {
        Notificacion::where('usuario_id', $usuarioId)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Todas las notificaciones eliminadas'
        ]);
    }

    public function marcarLeida($notificacionId)
    {
        $notificacion = Notificacion::find($notificacionId);

        if (!$notificacion) {
            return response()->json(['success' => false, 'message' => 'Notificación no encontrada'], 404);
        }

        $notificacion->update(['leida' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Notificación marcada como leída',
            'data' => $notificacion
        ]);
    }

    public function destroy($notificacionId)
    {
        $notificacion = Notificacion::find($notificacionId);

        if (!$notificacion) {
            return response()->json(['success' => false, 'message' => 'Notificación no encontrada'], 404);
        }

        $notificacion->delete();

        return response()->json([
            'success' => true,
            'message' => 'Notificación eliminada'
        ]);
    }
}