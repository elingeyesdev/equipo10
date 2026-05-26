<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('respuestas', function (Blueprint $table) {
            $table->string('estado_evidencia')->default('pending')->after('util');
        });
        // Marcar todas las existentes como approved para no romper nada
        \Illuminate\Support\Facades\DB::table('respuestas')
            ->where('tipo_respuesta', 'avistamiento')
            ->update(['estado_evidencia' => 'approved']);
    }

    public function down(): void {
        Schema::table('respuestas', function (Blueprint $table) {
            $table->dropColumn('estado_evidencia');
        });
    }
};
