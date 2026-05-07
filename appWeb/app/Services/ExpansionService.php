<?php

namespace App\Services;

use App\Models\Reporte;
use App\Models\Cuadrante;
use App\Models\ExpansionReporte;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ExpansionService
{
    /**
     * Tiempos de expansión por nivel (en minutos desde la creación)
     * L1: 0m (Inicio)
     * L2: 30m
     * L3: 60m (1h)
     * L4: 180m (3h)
     * L5: 360m (6h)
     * L6: 720m (12h)
     * L7: 1440m (24h)
     * L8: 2880m (48h)
     * L9: 4320m (72h)
     * L10: 5760m (96h / 4 días) - Límite Sugerido
     */
    protected static $niveles = [
        1 => 0,
        2 => 30,
        3 => 60,
        4 => 180,
        5 => 360,
        6 => 720,
        7 => 1440,
        8 => 2880,
        9 => 4320,
        10 => 5760
    ];

    public function procesarExpansiones()
    {
        // 1. Procesar Reportes
        $reportes = Reporte::where('estado', 'activo')
            ->where('nivel_expansion', '<', 10)
            ->where('proxima_expansion', '<=', now())
            ->get();

        $count = 0;
        foreach ($reportes as $reporte) {
            if ($this->expandir($reporte)) {
                $count++;
            }
        }

        // 2. Procesar Pistas (Respuestas) de forma independiente
        // Solo las que tienen ubicación (lat/lng)
        $pistas = \App\Models\Respuesta::whereNotNull('ubicacion_lat')
            ->where('nivel_expansion', '<', 10)
            ->where('proxima_expansion', '<=', now())
            ->get();

        foreach ($pistas as $pista) {
            $this->expandirPista($pista);
            $count++;
        }

        return $count;
    }

    public function expandirPista($pista)
    {
        if ($pista->nivel_expansion >= 10) return false;

        $nuevoNivel = $pista->nivel_expansion + 1;
        
        // Calcular próxima expansión para la pista
        $proximaFecha = null;
        if ($nuevoNivel < 10) {
            $minutosParaSiguiente = self::$niveles[$nuevoNivel + 1];
            $proximaFecha = $pista->created_at->copy()->addMinutes($minutosParaSiguiente);
            
            if ($proximaFecha->isPast()) {
                $proximaFecha = now()->addMinutes(30); // Si ya pasó, programar en 30 min
            }
        }

        $pista->update([
            'nivel_expansion' => $nuevoNivel,
            'proxima_expansion' => $proximaFecha
        ]);

        return true;
    }

    public function expandir(Reporte $reporte)
    {
        if ($reporte->estado !== 'activo') return false;
        if ($reporte->nivel_expansion >= 10) return false;

        try {
            DB::beginTransaction();

            $cuadranteOrigen = $reporte->cuadrante;
            if (!$cuadranteOrigen) return false;

            $nuevoNivel = $reporte->nivel_expansion + 1;
            
            // La distancia (anillo) es igual al nivel - 1
            // L2 = d1 (3x3), L3 = d2 (5x5), etc.
            $distancia = $nuevoNivel - 1;

            $filaCentral = $cuadranteOrigen->fila;
            $colCentral = $cuadranteOrigen->columna;

            // Encontrar todos los cuadrantes dentro de la distancia Chebyshev
            $filasAfectadas = [];
            for ($i = -$distancia; $i <= $distancia; $i++) {
                $filasAfectadas[] = chr(ord($filaCentral) + $i);
            }

            $colMin = $colCentral - $distancia;
            $colMax = $colCentral + $distancia;

            $cuadrantesNuevos = Cuadrante::whereIn('fila', $filasAfectadas)
                ->where('columna', '>=', $colMin)
                ->where('columna', '<=', $colMax)
                ->where('activo', true)
                ->get();

            foreach ($cuadrantesNuevos as $cuadrante) {
                // Registrar solo si no existe ya para este reporte
                $exists = ExpansionReporte::where('reporte_id', $reporte->id)
                    ->where('cuadrante_expandido_id', $cuadrante->id)
                    ->exists();

                if (!$exists) {
                    ExpansionReporte::create([
                        'reporte_id' => $reporte->id,
                        'cuadrante_original_id' => $reporte->cuadrante_id,
                        'cuadrante_expandido_id' => $cuadrante->id,
                        'nivel' => $nuevoNivel,
                        'fecha_expansion' => now()
                    ]);

                    // Aquí se podrían enviar notificaciones push a los voluntarios de ese cuadrante
                }
            }

            // Calcular próxima expansión
            $proximaFecha = null;
            if ($nuevoNivel < 10) {
                $minutosParaSiguiente = self::$niveles[$nuevoNivel + 1];
                $proximaFecha = $reporte->created_at->copy()->addMinutes($minutosParaSiguiente);
                
                // Si la fecha calculada ya pasó (ej: estuvo pausado), ponerla para dentro de poco
                if ($proximaFecha->isPast()) {
                    $proximaFecha = now()->addMinutes(5);
                }
            }

            $reporte->update([
                'nivel_expansion' => $nuevoNivel,
                'proxima_expansion' => $proximaFecha
            ]);

            DB::commit();
            return true;

        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error("Error expandiendo reporte {$reporte->id}: " . $e->getMessage());
            return false;
        }
    }

    public static function getSiguienteExpansion(Carbon $createdAt, int $nivelActual)
    {
        $siguienteNivel = $nivelActual + 1;
        if (!isset(self::$niveles[$siguienteNivel])) return null;

        return $createdAt->copy()->addMinutes(self::$niveles[$siguienteNivel]);
    }
}