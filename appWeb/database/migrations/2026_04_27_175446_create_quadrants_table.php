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
        // Habilitar extensión PostGIS en PostgreSQL si no está ya activa
        if (config('database.default') === 'pgsql') {
            DB::statement('CREATE EXTENSION IF NOT EXISTS postgis;');
        }

        // E7.4. Crear migración para la tabla quadrants con soporte para datos espaciales
        // Nota: Se asume el uso de PostgreSQL con PostGIS o MySQL con soporte espacial.
        Schema::create('quadrants', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('code', 20)->unique();
            $table->string('name', 100);
            
            // Soporte para datos espaciales nativos (Polygon)
            // SRID 4326 es el estándar para WGS84 (GPS)
            $table->geometry('shape', 'polygon', 4326);
            
            // Punto central como dato espacial
            $table->geometry('center_point', 'point', 4326)->nullable();
            
            $table->string('city', 100);
            $table->boolean('active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('quadrants');
    }
};
