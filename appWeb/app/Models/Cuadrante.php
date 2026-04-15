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
}