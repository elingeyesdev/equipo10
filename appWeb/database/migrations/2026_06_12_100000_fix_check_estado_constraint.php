<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Elimina el constraint check_estado para permitir todos los estados
     * (cerrado, pausado, activo, resuelto, inactivo, spam).
     * Esto soluciona el error SQLSTATE[23514] al cerrar/pausar búsquedas.
     */
    public function up(): void
    {
        // Eliminar el constraint viejo (si existe) que no incluía 'cerrado' ni 'pausado'
        DB::statement('ALTER TABLE reportes DROP CONSTRAINT IF EXISTS check_estado');

        // Añadir constraint actualizado con todos los estados válidos
        DB::statement("ALTER TABLE reportes ADD CONSTRAINT check_estado CHECK (estado IN ('activo', 'resuelto', 'inactivo', 'spam', 'cerrado', 'pausado'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE reportes DROP CONSTRAINT IF EXISTS check_estado');
        DB::statement("ALTER TABLE reportes ADD CONSTRAINT check_estado CHECK (estado IN ('activo', 'resuelto', 'inactivo', 'spam'))");
    }
};
