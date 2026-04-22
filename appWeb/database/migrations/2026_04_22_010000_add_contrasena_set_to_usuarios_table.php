<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('usuarios', function (Blueprint $table) {
            // Indica si el usuario tiene una contraseña real establecida.
            // false = creado por admin sin contraseña, puede completar su cuenta desde la app móvil.
            // true  = usuario registrado normalmente con su propia contraseña.
            $table->boolean('contrasena_set')->default(false)->after('contrasena');
        });

        // Los usuarios ya existentes que tienen contrasena no vacía se marcan como true
        DB::statement("UPDATE usuarios SET contrasena_set = true WHERE contrasena IS NOT NULL AND contrasena != ''");
    }

    public function down(): void
    {
        Schema::table('usuarios', function (Blueprint $table) {
            $table->dropColumn('contrasena_set');
        });
    }
};
