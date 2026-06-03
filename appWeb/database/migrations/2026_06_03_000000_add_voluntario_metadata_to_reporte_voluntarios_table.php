<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Agrega metadata opcional del voluntario al momento de unirse.
     * Permite al coordinador conocer las capacidades del voluntario antes
     * de asignarle una zona de búsqueda.
     */
    public function up(): void
    {
        Schema::table('reporte_voluntarios', function (Blueprint $table) {
            // Habilidades que el voluntario ofrece en este operativo específico
            // (puede diferir de las habilidades globales de su perfil)
            $table->jsonb('habilidades_ofrecidas')->nullable()->after('recorrido_puntos');

            // Indica si el voluntario dispone de vehículo para el operativo
            $table->boolean('tiene_vehiculo')->default(false)->after('habilidades_ofrecidas');

            // Tipo / descripción del vehículo (ej: "Camioneta 4x4", "Moto")
            $table->string('tipo_vehiculo', 100)->nullable()->after('tiene_vehiculo');

            // Disponibilidad estimada de tiempo en horas (ej: "1h", "2h", "4h", "Todo el día")
            $table->string('disponibilidad_horas', 20)->nullable()->after('tipo_vehiculo');
        });
    }

    public function down(): void
    {
        Schema::table('reporte_voluntarios', function (Blueprint $table) {
            $table->dropColumn([
                'habilidades_ofrecidas',
                'tiene_vehiculo',
                'tipo_vehiculo',
                'disponibilidad_horas',
            ]);
        });
    }
};
