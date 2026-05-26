<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\ExpansionService;
use App\Models\Reporte;

class ProcessExpansionsCommand extends Command
{
    protected $signature = 'app:process-expansions';
    protected $description = 'Procesa las expansiones automáticas de los reportes activos por niveles de tiempo';

    public function handle(ExpansionService $expansionService)
    {
        $this->info('Iniciando procesamiento de expansiones...');
        
        // Obtener todos los reportes activos que ya pasaron su proxima_expansion
        $reportes = Reporte::with('cuadrante')
            ->where('estado', 'activo')
            ->where('nivel_expansion', '<', 10)
            ->where('proxima_expansion', '<=', now())
            ->get();

        $this->comment("Reportes pendientes de expansion: {$reportes->count()}");

        if ($reportes->isEmpty()) {
            $this->comment('No hay reportes que necesiten expansión en este momento.');
            return;
        }

        $expandidos = 0;
        foreach ($reportes as $reporte) {
            $nivelAnterior = $reporte->nivel_expansion;
            $resultado = $expansionService->expandir($reporte);
            
            if ($resultado) {
                $reporte->refresh();
                $this->line("<info>{$reporte->titulo}</info> expandido: Nivel {$nivelAnterior} -> <comment>{$reporte->nivel_expansion}</comment>");
                $expandidos++;
            } else {
                $this->warn("{$reporte->titulo} no pudo expandirse (revisar logs)");
            }
        }
        
        $this->info("Procesamiento completado. Expandidos: {$expandidos}");
    }
}
