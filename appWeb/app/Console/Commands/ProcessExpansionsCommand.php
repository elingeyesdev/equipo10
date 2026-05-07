<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\ExpansionService;

class ProcessExpansionsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:process-expansions';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Procesa las expansiones automáticas de los reportes activos por niveles de tiempo';

    /**
     * Execute the console command.
     */
    public function handle(ExpansionService $expansionService)
    {
        $this->info('Iniciando procesamiento de expansiones...');
        
        $reportes = \App\Models\Reporte::where('estado', 'activo')
            ->where('nivel_expansion', '<', 10)
            ->where('proxima_expansion', '<=', now())
            ->get();

        if ($reportes->isEmpty()) {
            $this->comment('No hay reportes que necesiten expansión en este momento.');
            return;
        }

        foreach ($reportes as $reporte) {
            $nivelAnterior = $reporte->nivel_expansion;
            if ($expansionService->expandir($reporte)) {
                $this->line("✅ <info>{$reporte->titulo}</info> expandido: Nivel {$nivelAnterior} -> <comment>{$reporte->nivel_expansion}</comment>");
            }
        }
        
        $this->info("Procesamiento completado.");
    }
}
