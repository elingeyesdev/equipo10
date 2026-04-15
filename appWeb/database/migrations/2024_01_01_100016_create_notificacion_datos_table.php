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
        Schema::create('notificacion_datos', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('notificacion_id');
            $table->string('clave', 100);
            $table->text('valor');
            $table->timestampTz('created_at')->default(DB::raw('NOW()'));

            $table->foreign('notificacion_id')
                ->references('id')
                ->on('notificaciones')
                ->onDelete('cascade');

            $table->unique(['notificacion_id', 'clave']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notificacion_datos');
    }
};



