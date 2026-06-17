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

    // estado: membresía del voluntario en la operación
    const PARTICIPACION_BUSCANDO  = 'buscando';   // activo en el equipo
    const PARTICIPACION_INACTIVO  = 'inactivo';   // se retiró temporalmente (puede volver)
    // 'finalizado' existe en el enum pero actualmente no se usa

    // estado_busqueda: sesión GPS del voluntario
    const SESION_ESPERANDO = 'esperando';  // inscrito pero sin iniciar tracking
    const SESION_ACTIVO    = 'activo';     // con GPS activo
    const SESION_EN_PAUSA  = 'en_pausa';  // tracking pausado
    const SESION_TERMINADO = 'terminado'; // sesión finalizada, recorrido guardado

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
        // Metadata opcional del voluntario al unirse
        'habilidades_ofrecidas',
        'tiene_vehiculo',
        'tipo_vehiculo',
        'disponibilidad_horas',
    ];

    protected $casts = [
        'ultima_coordenada_lat' => 'decimal:8',
        'ultima_coordenada_lng' => 'decimal:8',
        'ultima_actualizacion_gps' => 'datetime',
        'inicio_busqueda' => 'datetime',
        'fin_busqueda' => 'datetime',
        'recorrido_puntos' => 'array',
        'habilidades_ofrecidas' => 'array',
        'tiene_vehiculo' => 'boolean',
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

    // Scopes de participación (campo: estado)
    public function scopeEnEquipo($query)
    {
        return $query->where('estado', self::PARTICIPACION_BUSCANDO);
    }

    public function scopeRetirados($query)
    {
        return $query->where('estado', self::PARTICIPACION_INACTIVO);
    }

    // Scopes de sesión GPS (campo: estado_busqueda)
    public function scopeConSesionActiva($query)
    {
        return $query->whereIn('estado_busqueda', [self::SESION_ACTIVO, self::SESION_EN_PAUSA]);
    }

    public function scopeConSesionTerminada($query)
    {
        return $query->where('estado_busqueda', self::SESION_TERMINADO);
    }
}
