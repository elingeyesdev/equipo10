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
        Schema::create('configuracion_sistema', function (Blueprint $table) {
            $table->string('clave', 100)->primary();
            $table->text('valor');
            $table->text('descripcion')->nullable();
            $table->string('tipo', 20)->default('string');
            $table->timestampTz('updated_at')->default(DB::raw('NOW()'));
        });

        // Constraint CHECK usando DB::statement
        DB::statement('ALTER TABLE configuracion_sistema ADD CONSTRAINT check_tipo CHECK (tipo IN (\'string\', \'number\', \'boolean\', \'json\'))');

        // Insertar configuraciones iniciales
        DB::table('configuracion_sistema')->insert([
            [
                'clave' => 'tiempo_expansion_horas',
                'valor' => '0.083',
                'descripcion' => 'Horas antes de expandir a cuadrantes adyacentes',
                'tipo' => 'number'
            ],
            [
                'clave' => 'max_nivel_expansion',
                'valor' => '3',
                'descripcion' => 'Máximo nivel de expansión permitido',
                'tipo' => 'number'
            ],
            [
                'clave' => 'radio_cuadrante_km',
                'valor' => '2',
                'descripcion' => 'Radio en kilómetros de cada cuadrante',
                'tipo' => 'number'
            ],
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('configuracion_sistema');
    }
};

