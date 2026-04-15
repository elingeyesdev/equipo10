<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class RestoreFromBackupSeeder extends Seeder
{
    public function run(): void
    {
        $backupPath = base_path('backup.sql');

        if (!File::exists($backupPath)) {
            $this->command->error("Backup file not found at: {$backupPath}");
            return;
        }

        $content = File::get($backupPath);

        // 1. Restore Cuadrantes
        $this->restoreTableFromCopy($content, 'cuadrantes', [
            'id', 'codigo', 'fila', 'columna', 'nombre', 'geometria', 'centro', 
            'lat_min', 'lat_max', 'lng_min', 'lng_max', 'ciudad', 'zona', 'barrios', 
            'activo', 'created_at', 'centro_lat', 'centro_lng'
        ]);

        // 2. Restore Grupos
        $this->restoreTableFromCopy($content, 'grupos', [
            'id', 'cuadrante_id', 'nombre', 'descripcion', 'imagen_url', 'publico', 
            'requiere_aprobacion', 'miembros_count', 'reportes_activos_count', 
            'reportes_resueltos_count', 'created_at', 'updated_at'
        ]);

        // 3. Restore Categorias
        $this->restoreTableFromCopy($content, 'categorias', [
            'id', 'nombre', 'icono', 'color', 'descripcion', 'activo', 'created_at', 'updated_at'
        ]);
        
        $this->command->info('✅ Data restoration from backup completed!');
    }

    private function restoreTableFromCopy(string $content, string $tableName, array $columns)
    {
        // Regex to find the COPY block - flexible for line endings and spacing
        // Matches: COPY public.tablename (col1, col2) FROM stdin;
        // Then captures the data block until \.
        $pattern = "/COPY public\.{$tableName}\s*\((.*?)\)\s*FROM stdin;[\r\n]+(.*?)(?:[\r\n]+)\\\./s";

        if (preg_match($pattern, $content, $matches)) {
            $dataBlock = $matches[2];
            $rows = preg_split("/\r\n|\n|\r/", $dataBlock);
            $count = 0;

            $this->command->info("Found COPY block for {$tableName}. Processing " . count($rows) . " rows.");
            
            foreach ($rows as $row) {
                if (empty(trim($row))) continue;

                $values = explode("\t", $row);
                
                if (count($values) !== count($columns)) {
                    $this->command->warn("Row column count mismatch for {$tableName}. Expected " . count($columns) . ", got " . count($values));
                    continue;
                }
                
                $insertData = [];
                foreach ($columns as $index => $column) {
                    $value = $values[$index] ?? null;
                    
                    if ($value === '\N') {
                        $value = null;
                    }
                    
                    if ($value === 't') $value = true;
                    if ($value === 'f') $value = false;

                    $insertData[$column] = $value;
                }

                try {
                    $shouldInsert = true;

                    // Check ID existence first
                    if (DB::table($tableName)->where('id', $insertData['id'])->exists()) {
                        $shouldInsert = false;
                    }

                    // For 'categorias', check 'nombre' unique constraint
                    if ($shouldInsert && $tableName === 'categorias' && isset($insertData['nombre'])) {
                        if (DB::table($tableName)->where('nombre', $insertData['nombre'])->exists()) {
                            $shouldInsert = false;
                            $this->command->warn("Skipping duplicate category name: " . $insertData['nombre']);
                        }
                    }

                    if ($shouldInsert) {
                         DB::table($tableName)->insert($insertData);
                         $count++;
                    }
                } catch (\Exception $e) {
                    $this->command->warn("Failed to insert row in {$tableName}: " . $e->getMessage());
                }
            }
            $this->command->info("Inserted {$count} rows into {$tableName}.");
        } else {
            $this->command->warn("No COPY block found for table {$tableName} in backup.sql (Regex mismatch)");
        }
    }
}
