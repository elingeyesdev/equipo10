<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('reportes', function (Blueprint $table) {
            $table->uuid('resuelto_por')->nullable()->after('estado');
            $table->text('historia_exito')->nullable()->after('resuelto_por');

            $table->foreign('resuelto_por')
                  ->references('id')->on('usuarios')
                  ->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reportes', function (Blueprint $table) {
            $table->dropForeign(['resuelto_por']);
            $table->dropColumn(['resuelto_por', 'historia_exito']);
        });
    }
};
