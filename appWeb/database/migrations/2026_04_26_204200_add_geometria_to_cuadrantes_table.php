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
        Schema::table('cuadrantes', function (Blueprint $table) {
            // Columna para guardar el dibujo complejo (Polígono) en formato JSON/GeoJSON
            $table->longText('geometria')->nullable()->after('nombre');
            // Columna para guardar el punto central del polígono
            $table->json('centro')->nullable()->after('geometria');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('cuadrantes', function (Blueprint $table) {
            $table->dropColumn(['geometria', 'centro']);
        });
    }
};
