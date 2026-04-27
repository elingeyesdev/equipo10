<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('respuestas', function (Blueprint $table) {
            $table->uuid('cuadrante_id')->nullable()->after('reporte_id');
            $table->foreign('cuadrante_id')->references('id')->on('cuadrantes')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('respuestas', function (Blueprint $table) {
            $table->dropForeign(['cuadrante_id']);
            $table->dropColumn('cuadrante_id');
        });
    }
};
