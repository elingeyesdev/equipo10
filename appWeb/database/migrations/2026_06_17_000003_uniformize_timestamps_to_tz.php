<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // reporte_voluntarios: timestamps y columnas de sesión GPS
        DB::statement('ALTER TABLE reporte_voluntarios ALTER COLUMN ultima_actualizacion_gps TYPE TIMESTAMPTZ USING ultima_actualizacion_gps AT TIME ZONE \'UTC\'');
        DB::statement('ALTER TABLE reporte_voluntarios ALTER COLUMN inicio_busqueda TYPE TIMESTAMPTZ USING inicio_busqueda AT TIME ZONE \'UTC\'');
        DB::statement('ALTER TABLE reporte_voluntarios ALTER COLUMN fin_busqueda TYPE TIMESTAMPTZ USING fin_busqueda AT TIME ZONE \'UTC\'');
        DB::statement('ALTER TABLE reporte_voluntarios ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'');
        DB::statement('ALTER TABLE reporte_voluntarios ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE \'UTC\'');

        // comentarios
        DB::statement('ALTER TABLE comentarios ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'');
        DB::statement('ALTER TABLE comentarios ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE \'UTC\'');

        // imagenes_almacenadas
        DB::statement('ALTER TABLE imagenes_almacenadas ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE \'UTC\'');
        DB::statement('ALTER TABLE imagenes_almacenadas ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE \'UTC\'');

        // Tabla huérfana: quadrants (experimental, sin modelo ni controller)
        Schema::dropIfExists('quadrants');
    }

    public function down(): void
    {
        // Revertir TIMESTAMPTZ a TIMESTAMP sin zona horaria
        $tablas = [
            'reporte_voluntarios' => ['ultima_actualizacion_gps', 'inicio_busqueda', 'fin_busqueda', 'created_at', 'updated_at'],
            'comentarios'         => ['created_at', 'updated_at'],
            'imagenes_almacenadas' => ['created_at', 'updated_at'],
        ];

        foreach ($tablas as $tabla => $columnas) {
            foreach ($columnas as $col) {
                DB::statement("ALTER TABLE {$tabla} ALTER COLUMN {$col} TYPE TIMESTAMP USING {$col} AT TIME ZONE 'UTC'");
            }
        }
    }
};
