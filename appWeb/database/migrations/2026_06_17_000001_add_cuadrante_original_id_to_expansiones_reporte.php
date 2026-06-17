<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('expansiones_reporte', function (Blueprint $table) {
            $table->uuid('cuadrante_original_id')->nullable()->after('reporte_id');

            $table->foreign('cuadrante_original_id')
                ->references('id')
                ->on('cuadrantes')
                ->onDelete('set null');

            // FK que faltaba desde la migración original
            $table->foreign('cuadrante_expandido_id')
                ->references('id')
                ->on('cuadrantes')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::table('expansiones_reporte', function (Blueprint $table) {
            $table->dropForeign(['cuadrante_original_id']);
            $table->dropForeign(['cuadrante_expandido_id']);
            $table->dropColumn('cuadrante_original_id');
        });
    }
};
