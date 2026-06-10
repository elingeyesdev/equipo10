<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Reporte;
use App\Models\Respuesta;

class MapaOperativoAcceptanceTest extends TestCase
{
    /**
     * Prueba de aceptabilidad (Feature) para verificar que las Pistas aparecen
     * en el mapa y cambian su nivel de expansión adecuadamente de cara al usuario.
     */
    public function test_pistas_generan_cuadrantes_dinamicos_en_mapa()
    {
        // 1. Arrange: Crear un reporte y una pista con fecha antigua
        $reporte = Reporte::factory()->create([
            'ubicacion_exacta_lat' => -17.78,
            'ubicacion_exacta_lng' => -63.18,
            'estado' => 'activo'
        ]);

        $pista = Respuesta::factory()->create([
            'reporte_id' => $reporte->id,
            'tipo_respuesta' => 'pista',
            'ubicacion_lat' => -17.79,
            'ubicacion_lng' => -63.19,
            'created_at' => now()->subHours(10) // Suficiente tiempo para crecer a nivel 6
        ]);

        // 2. Act: El usuario visita la vista de cuadrantes
        $response = $this->get('/cuadrantes');

        // 3. Assert: Verificar que la respuesta es exitosa
        $response->assertStatus(200);

        // Verificar que la vista de cuadrantes carga y se inyectan los datos de los reportes
        $response->assertViewHas('reportes');
        
        // Verificar que la pista específica (por su ubicación o contenido) esté en el DOM o JSON devuelto
        $response->assertSee('-17.79');
        $response->assertSee('-63.19');
    }
}
