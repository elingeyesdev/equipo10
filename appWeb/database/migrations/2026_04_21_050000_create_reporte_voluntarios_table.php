<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('reporte_voluntarios', function (Blueprint $table) {
            $table->uuid('id')->primary();
            
            $table->uuid('reporte_id');
            $table->foreign('reporte_id')->references('id')->on('reportes')->onDelete('cascade');
            
            $table->uuid('usuario_id');
            $table->foreign('usuario_id')->references('id')->on('usuarios')->onDelete('cascade');
            
            $table->enum('estado', ['buscando', 'inactivo', 'finalizado'])->default('buscando');
            $table->decimal('ultima_coordenada_lat', 10, 8)->nullable();
            $table->decimal('ultima_coordenada_lng', 11, 8)->nullable();
            $table->timestamp('ultima_actualizacion_gps')->nullable();
            
            $table->timestamps();
            
            // Garantizar que no se asigne dos veces en estado buscando
            $table->unique(['reporte_id', 'usuario_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reporte_voluntarios');
    }
};
