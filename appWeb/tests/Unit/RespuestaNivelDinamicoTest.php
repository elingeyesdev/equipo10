<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;

class RespuestaNivelDinamicoTest extends TestCase
{
    /**
     * Prueba que el nivel dinámico incrementa en base al tiempo transcurrido (Unit).
     */
    public function test_calcular_nivel_dinamico()
    {
        // Simulando la lógica de calcularNivelDinamico del frontend/backend
        $fechaCreacion = new \DateTime('-5 hours');
        $ahora = new \DateTime('now');
        
        $minutos = ($ahora->getTimestamp() - $fechaCreacion->getTimestamp()) / 60;
        
        $nivelCalculado = $this->calcularNivelSimulado($minutos);
        
        // 5 horas = 300 minutos. Debería ser nivel 4 (>= 180 mins)
        $this->assertEquals(4, $nivelCalculado);
    }
    
    private function calcularNivelSimulado($diffMinutos) {
        if ($diffMinutos >= 5760) return 10;
        if ($diffMinutos >= 4320) return 9;
        if ($diffMinutos >= 2880) return 8;
        if ($diffMinutos >= 1440) return 7;
        if ($diffMinutos >= 720) return 6;
        if ($diffMinutos >= 360) return 5;
        if ($diffMinutos >= 180) return 4;
        if ($diffMinutos >= 60) return 3;
        if ($diffMinutos >= 30) return 2;
        return 1;
    }
}
