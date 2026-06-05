<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cuadrante extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'cuadrantes';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false; 

    protected $fillable = [
        'codigo',
        'fila',
        'columna',
        'nombre',
        'geometria',
        'centro',
        'lat_min',
        'lat_max',
        'lng_min',
        'lng_max',
        'ciudad',
        'zona',
        'barrios',
        'activo',
    ];

    protected $casts = [
        'columna' => 'integer',
        'lat_min' => 'decimal:8',
        'lat_max' => 'decimal:8',
        'lng_min' => 'decimal:8',
        'lng_max' => 'decimal:8',
        'centro_lat' => 'decimal:8',
        'centro_lng' => 'decimal:8',
        'barrios' => 'array',
        'activo' => 'boolean',
        'created_at' => 'datetime',
    ];

    protected $attributes = [
        'activo' => true,
    ];

    
    public function barrios()
    {
        return $this->hasMany(CuadranteBarrio::class, 'cuadrante_id');
    }
    public function reportes()
    {
        return $this->hasMany(Reporte::class,'cuadrante_id');
    }

    public function grupos()
    {
        return $this->hasMany(Grupo::class,'cuadrante_id');
    }

    public function expansionesOriginales()
    {
        return $this->hasMany(ExpansionReporte::class, 'cuadrante_original_id');
    }

    public function expansionesExpandidas()
    {
        return $this->hasMany(ExpansionReporte::class, 'cuadrante_expandido_id');
    }

    
    public function scopeActivos($query)
    {
        return $query->where('activo', true);
    }

    public function scopePorCiudad($query, $ciudad)
    {
        return $query->where('ciudad', $ciudad);
    }

    public function scopePorZona($query, $zona)
    {
        return $query->where('zona', $zona);
    }

    public function scopePorFila($query, $fila)
    {
        return $query->where('fila', $fila);
    }

    public function scopePorColumna($query, $columna)
    {
        return $query->where('columna', $columna);
    }

    
    public function esActivo()
    {
        return $this->activo === true;
    }

    public function getCoordenadas()
    {
        return [
            'lat_min' => $this->lat_min,
            'lat_max' => $this->lat_max,
            'lng_min' => $this->lng_min,
            'lng_max' => $this->lng_max,
        ];
    }

    public function getCentro()
    {
        return [
            'lat' => ($this->lat_min + $this->lat_max) / 2,
            'lng' => ($this->lng_min + $this->lng_max) / 2,
        ];
    }

    public function contieneUbicacion($lat, $lng)
    {
        return $lat >= $this->lat_min 
            && $lat <= $this->lat_max 
            && $lng >= $this->lng_min 
            && $lng <= $this->lng_max;
    }

    public function getCuadrantesAdyacentes()
    {
        return self::where(function($query) {
            
            $query->where('fila', $this->fila)
                  ->whereIn('columna', [$this->columna - 1, $this->columna + 1]);
        })->orWhere(function($query) {
            
            $filaActual = ord($this->fila);
            $filaAnterior = chr($filaActual - 1);
            $filaSiguiente = chr($filaActual + 1);
            
            $query->whereIn('fila', [$filaAnterior, $filaSiguiente])
                  ->where('columna', $this->columna);
        })->where('activo', true)
          ->get();
    }

    public function reportesActivos()
    {
        return $this->reportes()->where('estado', 'activo')->count();
    }

    public function reportesResueltos()
    {
        return $this->reportes()->where('estado', 'resuelto')->count();
    }

    public static function detectByLocation($lat, $lng)
    {
        $candidatos = self::where('activo', true)
            ->where(function($q) use ($lat) {
                $q->where(function($sq) use ($lat) {
                    $sq->where('lat_min', '<=', $lat)->where('lat_max', '>=', $lat);
                })->orWhere(function($sq) use ($lat) {
                    $sq->where('lat_min', '>=', $lat)->where('lat_max', '<=', $lat);
                });
            })
            ->where(function($q) use ($lng) {
                $q->where(function($sq) use ($lng) {
                    $sq->where('lng_min', '<=', $lng)->where('lng_max', '>=', $lng);
                })->orWhere(function($sq) use ($lng) {
                    $sq->where('lng_min', '>=', $lng)->where('lng_max', '<=', $lng);
                });
            })
            ->get();

        if ($candidatos->isEmpty()) {
            return null;
        }

        // 2. Verificación Geométrica Precisa
        foreach ($candidatos as $c) {
            if (!$c->geometria) continue;
            
            $geo = json_decode($c->geometria, true);
            if (!$geo) continue;

            $polygon = null;
            if (isset($geo['geometry']['coordinates'][0])) {
                $polygon = $geo['geometry']['coordinates'][0];
            } elseif (isset($geo['coordinates'][0])) {
                $polygon = $geo['coordinates'][0];
            }

            if ($polygon && self::isPointInPolygon($lat, $lng, $polygon)) {
                return $c;
            }
        }

        // 3. Fallback: Si no hay geometría o la precisión falló,
        // pero estamos dentro del bounding box de un candidato, usar el primero que sea cuadrícula base (sin geometría).
        $fallback = $candidatos->first(function ($c) {
            return is_null($c->geometria);
        });

        return $fallback ?: $candidatos->first();
    }

    /**
     * Algoritmo de Ray Casting
     */
    private static function isPointInPolygon($lat, $lng, $polygon)
    {
        $inside = false;
        $n = count($polygon);
        if ($n < 3) return false;

        for ($i = 0, $j = $n - 1; $i < $n; $j = $i++) {
            $xi = (float)$polygon[$i][0]; $yi = (float)$polygon[$i][1];
            $xj = (float)$polygon[$j][0]; $yj = (float)$polygon[$j][1];

            if ((($yi > $lat) != ($yj > $lat)) &&
                ($lng < ($xj - $xi) * ($lat - $yi) / ($yj - $yi) + $xi)) {
                $inside = !$inside;
            }
        }
        return $inside;
    }
}