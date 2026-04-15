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
        Schema::create('cuadrantes', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->string('codigo', 20)->unique();
            $table->string('fila', 5);
            $table->integer('columna');
            $table->string('nombre', 100)->nullable();
            $table->decimal('lat_min', 10, 8);
            $table->decimal('lat_max', 10, 8);
            $table->decimal('lng_min', 11, 8);
            $table->decimal('lng_max', 11, 8);
            $table->decimal('centro_lat', 10, 8)->nullable();
            $table->decimal('centro_lng', 11, 8)->nullable();
            $table->string('ciudad', 100);
            $table->string('zona', 100)->nullable();
            $table->boolean('activo')->default(true);
            $table->timestampTz('created_at')->default(DB::raw('NOW()'));

            $table->unique(['fila', 'columna']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cuadrantes');
    }
};



