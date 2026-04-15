<?php

namespace App\Services;

use App\Models\Reporte;
use App\Models\Cuadrante;
use App\Models\ExpansionReporte;
use App\Models\ConfiguracionSistema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ExpansionService
{
    /**
     * Verificar y expandir reportes que cumplan las condiciones
     */
    public static function verificarYExpandirReportes()
    {
        // Obtener configuración
        $tiempoHoras = ConfiguracionSistema::where('clave', 'tiempo_expansion_horas')->first()->valor ?? 24;
        $tiempoMinutos = ConfiguracionSistema::where('clave', 'tiempo_expansion_minutos')->first()->valor ?? 0;
        $maxNivelExpansion = ConfiguracionSistema::where('clave', 'max_nivel_expansion')->first()->valor ?? 2;

        // Calcular tiempo total en minutos
        $tiempoTotalMinutos = ($tiempoHoras * 60) + $tiempoMinutos;

        Log::info("🔍 Verificando reportes para expansión", [
            'tiempo_horas' => $tiempoHoras,
            'tiempo_minutos' => $tiempoMinutos,
            'max_nivel' => $maxNivelExpansion
        ]);

        // Buscar reportes activos que necesiten expansión
        $reportes = Reporte::where('estado', 'activo')
            ->where('nivel_expansion', '<', $maxNivelExpansion)
            ->where(function($query) use ($tiempoTotalMinutos) {
                // Primera expansión: desde creación
                $query->where('nivel_expansion', 0)
                      ->where('created_at', '<=', now()->subMinutes($tiempoTotalMinutos))
                // O expansiones subsecuentes: desde última expansión
                ->orWhere(function($q) use ($tiempoTotalMinutos) {
                    $q->where('nivel_expansion', '>', 0)
                      ->where('proxima_expansion', '<=', now());
                });
            })
            ->get();

        Log::info("📋 Reportes encontrados para expansión: " . $reportes->count());

        $expandidos = 0;
        foreach ($reportes as $reporte) {
            if (self::expandirReporte($reporte)) {
                $expandidos++;
            }
        }

        Log::info("✅ Expansión completada", [
            'reportes_expandidos' => $expandidos,
            'total_verificados' => $reportes->count()
        ]);

        return [
            'verificados' => $reportes->count(),
            'expandidos' => $expandidos
        ];
    }

    /**
     * Expandir un reporte específico
     */
    public static function expandirReporte(Reporte $reporte)
    {
        DB::beginTransaction();
        try {
            $nuevoNivel = $reporte->nivel_expansion + 1;
            
            Log::info("🔄 Expandiendo reporte", [
                'reporte_id' => $reporte->id,
                'titulo' => $reporte->titulo,
                'nivel_actual' => $reporte->nivel_expansion,
                'nuevo_nivel' => $nuevoNivel
            ]);

            // Obtener cuadrantes adyacentes
            $cuadrantesAdyacentes = self::obtenerCuadrantesAdyacentes($reporte->cuadrante);

            if ($cuadrantesAdyacentes->isEmpty()) {
                Log::warning("⚠️ No hay cuadrantes adyacentes", [
                    'reporte_id' => $reporte->id
                ]);
                DB::rollBack();
                return false;
            }

            // Crear expansiones
            $expansionesCreadas = 0;
            foreach ($cuadrantesAdyacentes as $cuadrante) {
                // Verificar si ya existe esta expansión
                $existente = ExpansionReporte::where('reporte_id', $reporte->id)
                    ->where('cuadrante_expandido_id', $cuadrante->id)
                    ->exists();

                if (!$existente) {
                    ExpansionReporte::create([
                        'reporte_id' => $reporte->id,
                        'cuadrante_expandido_id' => $cuadrante->id,
                        'nivel' => $nuevoNivel,
                        'fecha_expansion' => now()
                    ]);
                    $expansionesCreadas++;
                    
                    Log::info("➕ Expansión creada", [
                        'cuadrante' => $cuadrante->codigo,
                        'nivel' => $nuevoNivel
                    ]);
                }
            }

            // Calcular próxima expansión si no es el último nivel
            $tiempoHoras = ConfiguracionSistema::where('clave', 'tiempo_expansion_horas')->first()->valor ?? 24;
            $tiempoMinutos = ConfiguracionSistema::where('clave', 'tiempo_expansion_minutos')->first()->valor ?? 0;
            $proximaExpansion = null;
            
            $maxNivel = ConfiguracionSistema::where('clave', 'max_nivel_expansion')->first()->valor ?? 2;
            if ($nuevoNivel < $maxNivel) {
                $proximaExpansion = now()->addHours($tiempoHoras)->addMinutes($tiempoMinutos);
            }

            // Actualizar reporte
            $reporte->update([
                'nivel_expansion' => $nuevoNivel,
                'proxima_expansion' => $proximaExpansion
            ]);

            DB::commit();
            
            Log::info("✅ Reporte expandido exitosamente", [
                'reporte_id' => $reporte->id,
                'nuevo_nivel' => $nuevoNivel,
                'expansiones_creadas' => $expansionesCreadas,
                'proxima_expansion' => $proximaExpansion
            ]);

            return true;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("❌ Error expandiendo reporte: " . $e->getMessage(), [
                'reporte_id' => $reporte->id,
                'trace' => $e->getTraceAsString()
            ]);
            return false;
        }
    }

    /**
     * Obtener cuadrantes adyacentes (los 8 alrededor)
     */
    private static function obtenerCuadrantesAdyacentes(Cuadrante $cuadrante)
    {
        // Extraer fila y columna del código
        // Formato esperado: letra(s) + número(s), ej: "A1", "B12", "AA23"
        preg_match('/^([A-Z]+)(\d+)$/', $cuadrante->codigo, $matches);
        
        if (count($matches) !== 3) {
            Log::error("❌ Formato de código inválido", [
                'codigo' => $cuadrante->codigo
            ]);
            return collect();
        }

        $filaLetra = $matches[1];
        $columna = (int) $matches[2];

        // Convertir letra a número (A=1, B=2, etc.)
        $filaNum = 0;
        $len = strlen($filaLetra);
        for ($i = 0; $i < $len; $i++) {
            $filaNum = $filaNum * 26 + (ord($filaLetra[$i]) - ord('A') + 1);
        }

        // Generar los 8 códigos adyacentes
        $codigosAdyacentes = [];
        for ($f = -1; $f <= 1; $f++) {
            for ($c = -1; $c <= 1; $c++) {
                // Saltar el cuadrante actual
                if ($f === 0 && $c === 0) continue;

                $nuevaFila = $filaNum + $f;
                $nuevaColumna = $columna + $c;

                // Validar que no sean negativos
                if ($nuevaFila <= 0 || $nuevaColumna <= 0) continue;

                // Convertir número de fila a letra
                $letraFila = self::numeroALetra($nuevaFila);
                $codigosAdyacentes[] = $letraFila . $nuevaColumna;
            }
        }

        Log::info("🔍 Buscando cuadrantes adyacentes", [
            'cuadrante_actual' => $cuadrante->codigo,
            'codigos_buscados' => $codigosAdyacentes
        ]);

        // Buscar en la base de datos
        return Cuadrante::whereIn('codigo', $codigosAdyacentes)
            ->where('activo', true)
            ->get();
    }

    /**
     * Convertir número a letra (1=A, 2=B, 26=Z, 27=AA, etc.)
     */
    private static function numeroALetra($num)
    {
        $letra = '';
        while ($num > 0) {
            $num--;
            $letra = chr(65 + ($num % 26)) . $letra;
            $num = floor($num / 26);
        }
        return $letra;
    }

    /**
     * Resolver un reporte (marcar como resuelto)
     */
    public static function resolverReporte(Reporte $reporte, $usuarioId)
    {
        DB::beginTransaction();
        try {
            // Verificar que el usuario sea el creador
            if ($reporte->usuario_id !== $usuarioId) {
                throw new \Exception('Solo el creador puede resolver el reporte');
            }

            // Actualizar estado
            $reporte->update([
                'estado' => 'resuelto'
            ]);

            // TODO: Agregar puntos al usuario que encontró
            // TODO: Enviar notificaciones

            DB::commit();
            
            Log::info("✅ Reporte resuelto", [
                'reporte_id' => $reporte->id,
                'usuario_id' => $usuarioId
            ]);

            return true;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("❌ Error resolviendo reporte: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Obtener todos los cuadrantes donde está visible un reporte
     */
    public static function obtenerCuadrantesVisibles(Reporte $reporte)
    {
        $cuadrantes = collect([$reporte->cuadrante]);

        if ($reporte->nivel_expansion > 0) {
            $expansiones = ExpansionReporte::where('reporte_id', $reporte->id)
                ->with('cuadranteExpandido')
                ->get();

            foreach ($expansiones as $expansion) {
                $cuadrantes->push($expansion->cuadranteExpandido);
            }
        }

        return $cuadrantes;
    }
}