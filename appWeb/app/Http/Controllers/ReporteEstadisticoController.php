<?php

namespace App\Http\Controllers;

use App\Models\Reporte;
use App\Models\Usuario;
use App\Models\Cuadrante;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;

use App\Models\Categoria;

class ReporteEstadisticoController extends Controller
{
    public function index()
    {
        return view('reportes.estadisticas');
    }

    
    private function getDatosEficacia($fechaInicio, $fechaFin)
    {
        return DB::table('reportes')
            ->join('cuadrantes', 'reportes.cuadrante_id', '=', 'cuadrantes.id')
            ->select(
                'cuadrantes.nombre as cuadrante',
                DB::raw('COUNT(reportes.id) as total_reportes'),
                DB::raw('SUM(CASE WHEN reportes.estado = \'resuelto\' THEN 1 ELSE 0 END) as recuperados'),
                DB::raw('ROUND((SUM(CASE WHEN reportes.estado = \'resuelto\' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(reportes.id), 0)), 2) as tasa_exito')
            )
            ->whereBetween('reportes.created_at', [$fechaInicio, $fechaFin])
            ->groupBy('cuadrantes.id', 'cuadrantes.nombre')
            ->orderByDesc('tasa_exito')
            ->get();
    }

    private function getDatosUsuarios($limit)
    {
        return Usuario::select('id', 'nombre', 'email', 'puntos_ayuda', 'fecha_registro')
            ->withCount(['reportes as reportes_creados', 'respuestas as ayudas_brindadas'])
            ->orderByDesc('puntos_ayuda')
            ->limit($limit)
            ->get();
    }

    private function getDatosTendencias($year, $categoriaId = null)
    {
         $query = Reporte::select(
                DB::raw('EXTRACT(MONTH FROM created_at) as mes'),
                DB::raw('COUNT(*) as total'),
                DB::raw('SUM(CASE WHEN tipo_reporte = \'perdido\' THEN 1 ELSE 0 END) as perdidos'),
                DB::raw('SUM(CASE WHEN estado = \'resuelto\' THEN 1 ELSE 0 END) as resueltos')
            )
            ->whereYear('created_at', $year);

        if ($categoriaId) {
            $query->where('categoria_id', $categoriaId);
        }

        return $query->groupBy('mes')
            ->orderBy('mes')
            ->get();
    }

    public function eficaciaCuadrante(Request $request)
    {
        $fechaInicio = $request->input('fecha_inicio', Carbon::now()->subMonths(3));
        $fechaFin = $request->input('fecha_fin', Carbon::now());

        $datos = $this->getDatosEficacia($fechaInicio, $fechaFin);

        $chartData = [
            'labels' => $datos->pluck('cuadrante'),
            'data' => $datos->pluck('tasa_exito'),
        ];

        return view('reportes.eficacia', compact('datos', 'chartData', 'fechaInicio', 'fechaFin'));
    }

    public function topUsuarios(Request $request)
    {
        $limit = $request->input('limit', 10);
        $usuarios = $this->getDatosUsuarios($limit);
            
        $top5Total = $usuarios->take(5)->sum('puntos_ayuda');
        $otrosTotal = Usuario::sum('puntos_ayuda') - $top5Total;
        
        $chartData = [
            'labels' => $usuarios->take(5)->pluck('nombre')->push('Otros'),
            'data' => $usuarios->take(5)->pluck('puntos_ayuda')->push($otrosTotal)
        ];

        return view('reportes.usuarios', compact('usuarios', 'chartData', 'limit'));
    }

    public function tendenciasTemporales(Request $request)
    {
        $year = $request->input('year', date('Y'));
        $categoriaId = $request->input('categoria_id');
        
        $incidentesPorMes = $this->getDatosTendencias($year, $categoriaId);
        $categorias = Categoria::orderBy('nombre')->get();

        $meses = [];
        $dataPerdidos = [];
        $dataResueltos = [];
        
        for ($i = 1; $i <= 12; $i++) {
            $meses[] = Carbon::create()->month($i)->locale('es')->monthName; // Localized month name
            $dato = $incidentesPorMes->firstWhere('mes', $i);
            $dataPerdidos[] = $dato ? $dato->perdidos : 0;
            $dataResueltos[] = $dato ? $dato->resueltos : 0;
        }

        $chartData = [
            'labels' => $meses,
            'perdidos' => $dataPerdidos,
            'resueltos' => $dataResueltos
        ];

        return view('reportes.tendencias', compact('chartData', 'year', 'categorias', 'categoriaId'));
    }

    private function getExportData(Request $request, $reporte)
    {
        $data = [];

        switch ($reporte) {
            case 'eficacia':
                $fechaInicio = $request->input('fecha_inicio', Carbon::now()->subMonths(3));
                $fechaFin = $request->input('fecha_fin', Carbon::now());
                $data['datos'] = $this->getDatosEficacia($fechaInicio, $fechaFin);
                $data['title'] = 'Reporte de Eficacia por Cuadrante';
                $data['meta'] = "Desde: $fechaInicio Hasta: $fechaFin";
                $data['columns'] = ['Cuadrante', 'Total Reportes', 'Recuperados', 'Tasa Éxito (%)'];
                $data['keys'] = ['cuadrante', 'total_reportes', 'recuperados', 'tasa_exito'];
                break;

            case 'usuarios':
                $limit = $request->input('limit', 20);
                $data['datos'] = $this->getDatosUsuarios($limit);
                $data['title'] = 'Ranking de Top Usuarios';
                $data['meta'] = "Top $limit usuarios";
                $data['columns'] = ['Usuario', 'Email', 'Puntos', 'Reportes', 'Ayudas'];
                $data['keys'] = ['nombre', 'email', 'puntos_ayuda', 'reportes_creados', 'ayudas_brindadas'];
                break;
            
            case 'tendencias':
                $year = $request->input('year', date('Y'));
                $rawDatos = $this->getDatosTendencias($year);
                $datos = [];
                for ($i = 1; $i <= 12; $i++) {
                    $dato = $rawDatos->firstWhere('mes', $i);
                    $datos[] = [
                        'mes' => Carbon::create()->month($i)->locale('es')->monthName,
                        'total' => $dato ? $dato->total : 0,
                        'perdidos' => $dato ? $dato->perdidos : 0,
                        'encontrados' => $dato ? $dato->encontrados : 0,
                    ];
                }
                $data['datos'] = $datos;
                $data['title'] = 'Tendencias Temporales ' . $year;
                $data['meta'] = "Año: $year";
                $data['columns'] = ['Mes', 'Total Incidentes', 'Objetos Perdidos', 'Objetos Encontrados'];
                $data['keys'] = ['mes', 'total', 'perdidos', 'encontrados'];
                break;
        }
        return $data;
    }

    public function exportarPDF(Request $request, $reporte)
    {
        $data = $this->getExportData($request, $reporte);
        $pdf = Pdf::loadView('reportes.pdf.generico', $data);
        return $pdf->download('reporte_'.$reporte.'.pdf');
    }
    
    public function exportarExcel(Request $request, $reporte)
    {
        $data = $this->getExportData($request, $reporte);
        
        $fileName = 'reporte_' . $reporte . '.csv';
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$fileName",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $callback = function() use ($data) {
            $file = fopen('php://output', 'w');
            
            
            fputs($file, "\xEF\xBB\xBF");
            

            fputcsv($file, $data['columns']);


            foreach ($data['datos'] as $row) {
                $line = [];
                foreach ($data['keys'] as $key) {
                    if (is_array($row)) {
                        $line[] = $row[$key] ?? '';
                    } elseif (is_object($row)) {
                        $line[] = $row->$key ?? '';
                    } else {
                        $line[] = '';
                    }
                }
                fputcsv($file, $line);
            }
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
