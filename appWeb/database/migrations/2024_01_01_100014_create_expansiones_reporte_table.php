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
        Schema::create('expansiones_reporte', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('reporte_id');
            $table->uuid('cuadrante_expandido_id');
            $table->integer('nivel');
            $table->timestampTz('fecha_expansion')->default(DB::raw('NOW()'));

            $table->foreign('reporte_id')
                ->references('id')
                ->on('reportes')
                ->onDelete('cascade');

            $table->unique(['reporte_id', 'cuadrante_expandido_id']);

            // Constraint CHECK (cuadrante_expandido_id no puede ser NULL)
            // Laravel no soporta directamente CHECK constraints complejos, 
            // pero el campo es NOT NULL por defecto, así que está cubierto
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('expansiones_reporte');
    }
};



