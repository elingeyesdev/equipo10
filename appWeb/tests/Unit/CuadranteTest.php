<?php

namespace Tests\Unit;

use App\Models\Cuadrante;
use PHPUnit\Framework\TestCase;

class CuadranteTest extends TestCase
{
    private function makeCuadrante(array $attrs = []): Cuadrante
    {
        $c = new Cuadrante();
        foreach (array_merge([
            'lat_min' => -1.0,
            'lat_max' =>  1.0,
            'lng_min' => -1.0,
            'lng_max' =>  1.0,
            'activo'  => true,
            'fila'    => 'A',
            'columna' => 1,
        ], $attrs) as $key => $value) {
            $c->$key = $value;
        }
        return $c;
    }

    public function test_ubicacion_dentro_del_cuadrante(): void
    {
        $cuadrante = $this->makeCuadrante([
            'lat_min' => 4.0,
            'lat_max' => 5.0,
            'lng_min' => -75.0,
            'lng_max' => -74.0,
        ]);

        $dentro = $cuadrante->contieneUbicacion(4.5, -74.5);
        $fueraArriba = $cuadrante->contieneUbicacion(6.0, -74.5);
        $fueraAbajo = $cuadrante->contieneUbicacion(3.0, -74.5);
        $fueraDerechaLng = $cuadrante->contieneUbicacion(4.5, -73.0);
        $fueraIzquierdaLng = $cuadrante->contieneUbicacion(4.5, -76.0);

        $this->assertTrue(
            $dentro,
            'Una ubicación dentro del cuadrante debe ser detectada correctamente.'
        );
        $this->assertFalse(
            $fueraArriba,
            'Una ubicación por encima (latitud mayor) debe estar fuera del cuadrante.'
        );
        $this->assertFalse(
            $fueraAbajo,
            'Una ubicación por debajo (latitud menor) debe estar fuera del cuadrante.'
        );
        $this->assertFalse(
            $fueraDerechaLng,
            'Una ubicación a la derecha (longitud mayor) debe estar fuera del cuadrante.'
        );
        $this->assertFalse(
            $fueraIzquierdaLng,
            'Una ubicación a la izquierda (longitud menor) debe estar fuera del cuadrante.'
        );
    }

    public function test_calculo_punto_central(): void
    {
        $cuadrante = $this->makeCuadrante([
            'lat_min' => 4.0,
            'lat_max' => 6.0,
            'lng_min' => -76.0,
            'lng_max' => -74.0,
        ]);

        $centro = $cuadrante->getCentro();

        $this->assertEquals(
            5.0,
            $centro['lat'],
            'La latitud central debe ser el promedio entre lat_min y lat_max.'
        );
        $this->assertEquals(
            -75.0,
            $centro['lng'],
            'La longitud central debe ser el promedio entre lng_min y lng_max.'
        );
    }
}
