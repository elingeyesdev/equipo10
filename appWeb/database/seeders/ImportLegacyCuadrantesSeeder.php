<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class ImportLegacyCuadrantesSeeder extends Seeder
{
    public function run(): void
    {
        $backupPath = base_path('backup.sql');

        if (!File::exists($backupPath)) {
            $this->command->error("No se encontró backup.sql en: {$backupPath}");
            return;
        }

        $content = File::get($backupPath);

        // 1. Restaurar Cuadrantes (Si no existen por código)
        $this->restoreTable($content, 'cuadrantes', [
            'id', 'codigo', 'fila', 'columna', 'nombre', 'lat_min', 'lat_max', 'lng_min', 'lng_max', 
            'centro_lat', 'centro_lng', 'ciudad', 'zona', 'activo', 'created_at'
        ]);

        // 2. Restaurar Barrios Asociados
        $this->restoreTable($content, 'cuadrante_barrios', [
            'id', 'cuadrante_id', 'nombre_barrio', 'created_at'
        ]);
        
        $this->command->info('Sincronizacion de cuadrantes originales completada!');
    }

    private function restoreTable(string $content, string $tableName, array $columns)
    {
        // Regex para encontrar el bloque COPY
        $pattern = "/COPY public\.{$tableName}\s*\((.*?)\)\s*FROM stdin;[\r\n]+(.*?)(?:[\r\n]+)\\\./s";

        if (preg_match($pattern, $content, $matches)) {
            $dataBlock = $matches[2];
            $rows = preg_split("/\r\n|\n|\r/", $dataBlock);
            $count = 0;
            $skipped = 0;

            $this->command->info("Procesando bloque COPY para {$tableName}...");
            
            foreach ($rows as $row) {
                if (empty(trim($row))) continue;

                $values = explode("\t", $row);
                if (count($values) !== count($columns)) continue;
                
                $insertData = [];
                foreach ($columns as $index => $column) {
                    $value = $values[$index] ?? null;
                    if ($value === '\N') $value = null;
                    if ($value === 't') $value = true;
                    if ($value === 'f') $value = false;
                    $insertData[$column] = $value;
                }

                try {
                    $exists = false;
                    if ($tableName === 'cuadrantes') {
                        // Evitar duplicados por código (A1, B2, etc)
                        $exists = DB::table('cuadrantes')->where('codigo', $insertData['codigo'])->exists();
                    } else {
                        // Para barrios, evitar duplicados por ID
                        $exists = DB::table($tableName)->where('id', $insertData['id'])->exists();
                    }

                    if (!$exists) {
                        DB::table($tableName)->insert($insertData);
                        $count++;
                    } else {
                        $skipped++;
                    }
                } catch (\Exception $e) {
                    // Ignorar errores de llaves foráneas si el cuadrante no se insertó
                }
            }
            $this->command->info("Tabla {$tableName}: {$count} insertados, {$skipped} ya existían.");
        } else {
            $this->command->warn("No se encontró el bloque de datos para {$tableName}.");
        }
    }
}
