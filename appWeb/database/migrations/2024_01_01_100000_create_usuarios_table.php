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
        // Habilitar extensión pgcrypto si no está habilitada
        DB::statement('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');

        Schema::create('usuarios', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('nombre', 100);
            $table->string('email', 255)->unique();
            $table->string('telefono', 20)->nullable();
            $table->text('avatar_url')->nullable();
            $table->integer('puntos_ayuda')->default(0);
            $table->timestampTz('fecha_registro')->default(DB::raw('NOW()'));
            $table->boolean('activo')->default(true);
            $table->decimal('ubicacion_actual_lat', 10, 8)->nullable();
            $table->decimal('ubicacion_actual_lng', 11, 8)->nullable();
            $table->string('rol', 20)->default('cliente');
            $table->text('contrasena')->default('');
            $table->timestampsTz();
        });

        // Constraint CHECK para rol usando DB::statement
        DB::statement('ALTER TABLE usuarios ADD CONSTRAINT check_rol CHECK (rol IN (\'cliente\', \'moderador\', \'admin\'))');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('usuarios');
    }
};

