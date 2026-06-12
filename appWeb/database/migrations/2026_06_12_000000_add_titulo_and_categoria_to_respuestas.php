<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('respuestas', function (Blueprint $table) {
            $table->string('titulo', 255)->nullable()->after('tipo_respuesta');
            $table->string('categoria_informacion', 100)->nullable()->after('titulo');
        });

        // Migrar datos existentes: convertir 'pista' a 'informacion'
        // El 'mensaje' viejo se mantiene, le ponemos 'Nueva pista' como categoría por defecto.
        DB::table('respuestas')
            ->where('tipo_respuesta', 'pista')
            ->update([
                'tipo_respuesta' => 'informacion',
                'categoria_informacion' => 'Nueva pista',
                'titulo' => 'Información Migrada',
            ]);
    }

    public function down(): void
    {
        Schema::table('respuestas', function (Blueprint $table) {
            $table->dropColumn(['titulo', 'categoria_informacion']);
        });
    }
};
