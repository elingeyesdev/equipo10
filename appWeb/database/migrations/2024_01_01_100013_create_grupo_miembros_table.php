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
        Schema::create('grupo_miembros', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('grupo_id');
            $table->uuid('usuario_id');
            $table->string('rol', 20)->default('miembro');
            $table->boolean('notificaciones_activas')->default(true);
            $table->timestampTz('joined_at')->default(DB::raw('NOW()'));

            $table->foreign('grupo_id')
                ->references('id')
                ->on('grupos')
                ->onDelete('cascade');

            $table->foreign('usuario_id')
                ->references('id')
                ->on('usuarios')
                ->onDelete('cascade');

            $table->unique(['grupo_id', 'usuario_id']);
        });

        // Constraint CHECK usando DB::statement
        DB::statement('ALTER TABLE grupo_miembros ADD CONSTRAINT check_rol CHECK (rol IN (\'miembro\', \'moderador\', \'admin\'))');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('grupo_miembros');
    }
};

