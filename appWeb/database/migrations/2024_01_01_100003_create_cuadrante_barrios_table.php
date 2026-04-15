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
        Schema::create('cuadrante_barrios', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('cuadrante_id');
            $table->string('nombre_barrio', 200);
            $table->timestampTz('created_at')->default(DB::raw('NOW()'));

            $table->foreign('cuadrante_id')
                ->references('id')
                ->on('cuadrantes')
                ->onDelete('cascade');

            $table->unique(['cuadrante_id', 'nombre_barrio']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cuadrante_barrios');
    }
};



