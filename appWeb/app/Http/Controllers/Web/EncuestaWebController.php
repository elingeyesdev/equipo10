<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\EncuestaSatisfaccion;
use Illuminate\Http\Request;

class EncuestaWebController extends Controller
{
    public function index()
    {
        // Métricas globales de Satisfacción
        $totalEncuestas = EncuestaSatisfaccion::count();
        $promedioSatisfaccion = $totalEncuestas > 0 ? round(EncuestaSatisfaccion::avg('puntuacion'), 1) : 0;

        // Distribución de estrellas
        $distribucionEstrellas = [];
        for ($i = 5; $i >= 1; $i--) {
            $count = EncuestaSatisfaccion::where('puntuacion', $i)->count();
            $porcentaje = $totalEncuestas > 0 ? round(($count / $totalEncuestas) * 100) : 0;
            $distribucionEstrellas[$i] = [
                'count' => $count,
                'porcentaje' => $porcentaje
            ];
        }

        // Reseñas con usuario y reporte paginadas
        $encuestas = EncuestaSatisfaccion::with(['usuario', 'reporte'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        // Mapeamos para la vista de manera segura
        $encuestas->getCollection()->transform(function ($enc) {
            $esCreador = $enc->reporte && $enc->usuario_id === $enc->reporte->usuario_id;
            return (object) [
                'usuario_nombre' => $enc->usuario?->nombre ?? 'Usuario eliminado',
                'rol'           => $esCreador ? 'Creador de búsqueda' : 'Voluntario',
                'reporte_titulo' => $enc->reporte?->titulo ?? 'Reporte eliminado',
                'puntuacion'    => $enc->puntuacion,
                'comentario'    => $enc->comentario,
                'fecha'         => $enc->created_at?->format('d/m/Y') ?? 'Fecha desconocida',
                'reporte_id'    => $enc->reporte_id,
            ];
        });

        return view('encuestas.index', compact(
            'totalEncuestas',
            'promedioSatisfaccion',
            'distribucionEstrellas',
            'encuestas'
        ));
    }
}
