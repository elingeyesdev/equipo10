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
        // Índices para mejorar el rendimiento de las consultas
        Schema::table('reporte_caracteristicas', function (Blueprint $table) {
            $table->index('reporte_id', 'idx_reporte_caracteristicas_reporte');
        });

        Schema::table('reporte_imagenes', function (Blueprint $table) {
            $table->index('reporte_id', 'idx_reporte_imagenes_reporte');
        });

        Schema::table('reporte_videos', function (Blueprint $table) {
            $table->index('reporte_id', 'idx_reporte_videos_reporte');
        });

        Schema::table('respuesta_imagenes', function (Blueprint $table) {
            $table->index('respuesta_id', 'idx_respuesta_imagenes_respuesta');
        });

        Schema::table('respuesta_videos', function (Blueprint $table) {
            $table->index('respuesta_id', 'idx_respuesta_videos_respuesta');
        });

        Schema::table('cuadrante_barrios', function (Blueprint $table) {
            $table->index('cuadrante_id', 'idx_cuadrante_barrios_cuadrante');
        });

        Schema::table('notificacion_datos', function (Blueprint $table) {
            $table->index('notificacion_id', 'idx_notificacion_datos_notificacion');
        });

        Schema::table('respuestas', function (Blueprint $table) {
            $table->index('reporte_id', 'idx_respuestas_reporte');
        });

        Schema::table('expansiones_reporte', function (Blueprint $table) {
            $table->index('reporte_id', 'idx_expansiones_reporte');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reporte_caracteristicas', function (Blueprint $table) {
            $table->dropIndex('idx_reporte_caracteristicas_reporte');
        });

        Schema::table('reporte_imagenes', function (Blueprint $table) {
            $table->dropIndex('idx_reporte_imagenes_reporte');
        });

        Schema::table('reporte_videos', function (Blueprint $table) {
            $table->dropIndex('idx_reporte_videos_reporte');
        });

        Schema::table('respuesta_imagenes', function (Blueprint $table) {
            $table->dropIndex('idx_respuesta_imagenes_respuesta');
        });

        Schema::table('respuesta_videos', function (Blueprint $table) {
            $table->dropIndex('idx_respuesta_videos_respuesta');
        });

        Schema::table('cuadrante_barrios', function (Blueprint $table) {
            $table->dropIndex('idx_cuadrante_barrios_cuadrante');
        });

        Schema::table('notificacion_datos', function (Blueprint $table) {
            $table->dropIndex('idx_notificacion_datos_notificacion');
        });

        Schema::table('respuestas', function (Blueprint $table) {
            $table->dropIndex('idx_respuestas_reporte');
        });

        Schema::table('expansiones_reporte', function (Blueprint $table) {
            $table->dropIndex('idx_expansiones_reporte');
        });
    }
};



