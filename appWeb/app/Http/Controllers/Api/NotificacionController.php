<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notificacion;
use App\Models\Usuario;
use App\Events\NuevaNotificacion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class NotificacionController extends Controller
{
    /**
     * Obtener notificaciones del usuario
     */
    public function index($usuarioId)
    {
        try {
            $notificaciones = Notificacion::where('usuario_id', $usuarioId)
                ->with('datos')
                ->orderBy('created_at', 'desc')
                ->get();

            $noLeidas = $notificaciones->where('leida', false)->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'notificaciones' => $notificaciones,
                    'total' => $notificaciones->count(),
                    'no_leidas' => $noLeidas
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener notificaciones',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener notificaciones no leídas
     */
    public function noLeidas($usuarioId)
    {
        try {
            $notificaciones = Notificacion::where('usuario_id', $usuarioId)
                ->where('leida', false)
                ->with('datos')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'notificaciones' => $notificaciones,
                    'total' => $notificaciones->count()
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener notificaciones',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marcar notificación como leída
     */
    public function marcarLeida($notificacionId)
    {
        try {
            $notificacion = Notificacion::findOrFail($notificacionId);

            $notificacion->update([
                'leida' => true
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Notificación marcada como leída',
                'data' => $notificacion
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al marcar notificación',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marcar todas las notificaciones como leídas
     */
    public function marcarTodasLeidas($usuarioId)
    {
        try {
            $actualizadas = Notificacion::where('usuario_id', $usuarioId)
                ->where('leida', false)
                ->update(['leida' => true]);

            return response()->json([
                'success' => true,
                'message' => 'Todas las notificaciones marcadas como leídas',
                'data' => [
                    'notificaciones_actualizadas' => $actualizadas
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al marcar notificaciones',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Eliminar notificación
     */
    public function destroy($notificacionId)
    {
        try {
            $notificacion = Notificacion::findOrFail($notificacionId);
            $notificacion->delete();

            return response()->json([
                'success' => true,
                'message' => 'Notificación eliminada exitosamente'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar notificación',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Eliminar todas las notificaciones del usuario
     */
    public function eliminarTodas($usuarioId)
    {
        try {
            $eliminadas = Notificacion::where('usuario_id', $usuarioId)->delete();

            return response()->json([
                'success' => true,
                'message' => 'Todas las notificaciones eliminadas',
                'data' => [
                    'notificaciones_eliminadas' => $eliminadas
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar notificaciones',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

