<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reporte_voluntarios', function (Blueprint $table) {
            // Estado de la sesión de búsqueda activa del voluntario
            // 'esperando' | 'activo' | 'en_pausa' | 'terminado'
            $table->string('estado_busqueda', 20)->default('esperando')->after('estado');

            // Timestamps de la sesión de búsqueda
            $table->timestamp('inicio_busqueda')->nullable()->after('estado_busqueda');
            $table->timestamp('fin_busqueda')->nullable()->after('inicio_busqueda');

            // Recorrido completo guardado al finalizar: array JSON de { lat, lng, ts }
            $table->jsonb('recorrido_puntos')->nullable()->after('fin_busqueda');
        });
    }

    public function down(): void
    {
        Schema::table('reporte_voluntarios', function (Blueprint $table) {
            $table->dropColumn(['estado_busqueda', 'inicio_busqueda', 'fin_busqueda', 'recorrido_puntos']);
        });
    }
};
