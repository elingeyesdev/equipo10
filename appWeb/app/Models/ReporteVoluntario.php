<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ReporteVoluntario extends Model
{
    use HasUuids;

    protected $table = 'reporte_voluntarios';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'reporte_id',
        'usuario_id',
        'estado',
        'ultima_coordenada_lat',
        'ultima_coordenada_lng',
        'ultima_actualizacion_gps',
        'estado_busqueda',
        'inicio_busqueda',
        'fin_busqueda',
        'recorrido_puntos',
    ];

    protected $casts = [
        'ultima_coordenada_lat' => 'decimal:8',
        'ultima_coordenada_lng' => 'decimal:8',
        'ultima_actualizacion_gps' => 'datetime',
        'inicio_busqueda' => 'datetime',
        'fin_busqueda' => 'datetime',
        'recorrido_puntos' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function reporte()
    {
        return $this->belongsTo(Reporte::class, 'reporte_id');
    }

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }
}
