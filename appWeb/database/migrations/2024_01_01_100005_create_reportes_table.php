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
        Schema::create('reportes', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('usuario_id');
            $table->uuid('categoria_id');
            $table->uuid('cuadrante_id');
            $table->string('tipo_reporte', 20);
            $table->string('titulo', 200);
            $table->text('descripcion');
            $table->decimal('ubicacion_exacta_lat', 10, 8)->nullable();
            $table->decimal('ubicacion_exacta_lng', 11, 8)->nullable();
            $table->text('direccion_referencia')->nullable();
            $table->timestampTz('fecha_perdida')->nullable();
            $table->timestampTz('fecha_reporte')->default(DB::raw('NOW()'));
            $table->string('estado', 20)->default('activo');
            $table->string('prioridad', 20)->default('normal');
            $table->integer('nivel_expansion')->default(1);
            $table->integer('max_expansion')->default(3);
            $table->timestampTz('proxima_expansion')->nullable();
            $table->boolean('contacto_publico')->default(true);
            $table->string('telefono_contacto', 20)->nullable();
            $table->string('email_contacto', 255)->nullable();
            $table->decimal('recompensa', 10, 2)->nullable();
            $table->integer('vistas')->default(0);
            $table->timestampsTz();

            $table->foreign('usuario_id')
                ->references('id')
                ->on('usuarios')
                ->onDelete('cascade');

            $table->foreign('categoria_id')
                ->references('id')
                ->on('categorias');

            $table->foreign('cuadrante_id')
                ->references('id')
                ->on('cuadrantes');
        });

        // Constraints CHECK usando DB::statement
        DB::statement('ALTER TABLE reportes ADD CONSTRAINT check_tipo_reporte CHECK (tipo_reporte IN (\'perdido\', \'encontrado\'))');
        DB::statement('ALTER TABLE reportes ADD CONSTRAINT check_estado CHECK (estado IN (\'activo\', \'resuelto\', \'inactivo\', \'spam\'))');
        DB::statement('ALTER TABLE reportes ADD CONSTRAINT check_prioridad CHECK (prioridad IN (\'baja\', \'normal\', \'alta\', \'urgente\'))');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reportes');
    }
};

