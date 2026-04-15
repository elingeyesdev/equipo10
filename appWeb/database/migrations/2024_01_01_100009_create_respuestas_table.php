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
        Schema::create('respuestas', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('reporte_id');
            $table->uuid('usuario_id');
            $table->string('tipo_respuesta', 20);
            $table->text('mensaje');
            $table->decimal('ubicacion_lat', 10, 8)->nullable();
            $table->decimal('ubicacion_lng', 11, 8)->nullable();
            $table->text('direccion_referencia')->nullable();
            $table->boolean('verificada')->default(false);
            $table->boolean('util')->nullable();
            $table->timestampTz('created_at')->default(DB::raw('NOW()'));

            $table->foreign('reporte_id')
                ->references('id')
                ->on('reportes')
                ->onDelete('cascade');

            $table->foreign('usuario_id')
                ->references('id')
                ->on('usuarios')
                ->onDelete('cascade');
        });

        // Constraint CHECK usando DB::statement
        DB::statement('ALTER TABLE respuestas ADD CONSTRAINT check_tipo_respuesta CHECK (tipo_respuesta IN (\'avistamiento\', \'encontrado\', \'informacion\', \'pregunta\'))');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('respuestas');
    }
};

