<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Cuadrante;
use Illuminate\Support\Str;

class ExpandGridCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:expand-grid';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Expande la cuadricula original (legacy) hacia el Este y el Sur';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $rows = range('A', 'Z'); // 26 rows
        $maxColumns = 35; // Expand right to col 35

        $latDiff = 0.009;
        $lngDiff = 0.011;

        // Base values from A1
        $baseLatMax = -17.7000;
        $baseLngMin = -63.2500;

        $created = 0;
        $existing = 0;

        foreach ($rows as $rIndex => $row) {
            for ($col = 1; $col <= $maxColumns; $col++) {
                $codigo = $row . $col;
                
                $latMax = $baseLatMax - ($rIndex * $latDiff);
                $latMin = $latMax - $latDiff;

                $lngMin = $baseLngMin + (($col - 1) * $lngDiff);
                $lngMax = $lngMin + $lngDiff;

                $exists = Cuadrante::where('codigo', $codigo)->exists();

                if (!$exists) {
                    Cuadrante::create([
                        'id' => (string) Str::uuid(),
                        'codigo' => $codigo,
                        'fila' => $row,
                        'columna' => $col,
                        'nombre' => "Cuadrante {$codigo}",
                        'lat_min' => $latMin,
                        'lat_max' => $latMax,
                        'lng_min' => $lngMin,
                        'lng_max' => $lngMax,
                        'centro_lat' => ($latMin + $latMax) / 2,
                        'centro_lng' => ($lngMin + $lngMax) / 2,
                        'ciudad' => 'Santa Cruz de la Sierra',
                        'zona' => null,
                        'activo' => true,
                    ]);
                    $created++;
                } else {
                    $existing++;
                }
            }
        }

        $this->info("Cuadrícula expandida. Creados: {$created}, Ya existentes: {$existing}");
    }
}
