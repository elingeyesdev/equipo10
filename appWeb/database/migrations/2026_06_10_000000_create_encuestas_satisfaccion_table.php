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
        Schema::create('encuestas_satisfaccion', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('reporte_id');
            $table->uuid('usuario_id');
            $table->integer('puntuacion');
            $table->text('comentario')->nullable();
            $table->timestampsTz();

            $table->foreign('reporte_id')
                ->references('id')
                ->on('reportes')
                ->onDelete('cascade');

            $table->foreign('usuario_id')
                ->references('id')
                ->on('usuarios')
                ->onDelete('cascade');
                
            // Evitar que el mismo usuario evalúe múltiples veces el mismo reporte
            $table->unique(['reporte_id', 'usuario_id']);
        });

        // Constraint para la escala Likert de 1 a 5
        DB::statement('ALTER TABLE encuestas_satisfaccion ADD CONSTRAINT check_puntuacion CHECK (puntuacion >= 1 AND puntuacion <= 5)');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('encuestas_satisfaccion');
    }
};
