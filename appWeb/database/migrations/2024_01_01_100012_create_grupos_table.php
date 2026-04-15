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
        Schema::create('grupos', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('cuadrante_id');
            $table->string('nombre', 200);
            $table->text('descripcion')->nullable();
            $table->text('imagen_url')->nullable();
            $table->boolean('publico')->default(true);
            $table->boolean('requiere_aprobacion')->default(false);
            $table->integer('miembros_count')->default(0);
            $table->integer('reportes_activos_count')->default(0);
            $table->integer('reportes_resueltos_count')->default(0);
            $table->timestampsTz();

            $table->foreign('cuadrante_id')
                ->references('id')
                ->on('cuadrantes');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('grupos');
    }
};



