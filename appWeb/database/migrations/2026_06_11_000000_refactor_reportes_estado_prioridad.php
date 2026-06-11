<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Eliminar el constraint de prioridad
        DB::statement('ALTER TABLE reportes DROP CONSTRAINT IF EXISTS check_prioridad');

        // 2. Eliminar la columna prioridad
        Schema::table('reportes', function (Blueprint $table) {
            $table->dropColumn('prioridad');
        });

        // 3. Añadir la columna motivo_cierre
        Schema::table('reportes', function (Blueprint $table) {
            $table->text('motivo_cierre')->nullable();
        });

        // 4. Actualizar el constraint de estado para incluir cerrado y pausado
        DB::statement('ALTER TABLE reportes DROP CONSTRAINT IF EXISTS check_estado');
        DB::statement('ALTER TABLE reportes ADD CONSTRAINT check_estado CHECK (estado IN (\'activo\', \'resuelto\', \'inactivo\', \'spam\', \'cerrado\', \'pausado\'))');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reportes', function (Blueprint $table) {
            $table->dropColumn('motivo_cierre');
            $table->string('prioridad', 20)->default('normal');
        });

        DB::statement('ALTER TABLE reportes DROP CONSTRAINT IF EXISTS check_estado');
        DB::statement('ALTER TABLE reportes ADD CONSTRAINT check_estado CHECK (estado IN (\'activo\', \'resuelto\', \'inactivo\', \'spam\'))');
        DB::statement('ALTER TABLE reportes ADD CONSTRAINT check_prioridad CHECK (prioridad IN (\'baja\', \'normal\', \'alta\', \'urgente\'))');
    }
};
