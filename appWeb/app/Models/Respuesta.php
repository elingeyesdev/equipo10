<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Respuesta extends Model
{
    use HasUuids;

    protected $table = 'respuestas';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    const UPDATED_AT = null;

    protected $fillable = [
        'reporte_id',
        'usuario_id',
        'tipo_respuesta',
        'mensaje',
        'ubicacion',
        'ubicacion_lat',
        'ubicacion_lng',
        'direccion_referencia',
        'imagenes',
        'videos',
        'verificada',
        'util'
    ];

    protected $casts = [
        'imagenes' => 'array',
        'videos' => 'array',
        'ubicacion_lat' => 'decimal:8',
        'ubicacion_lng' => 'decimal:8',
        'verificada' => 'boolean',
        'util' => 'boolean',
        'created_at' => 'datetime'
    ];

    public function reporte()
    {
        return $this->belongsTo(Reporte::class, 'reporte_id');
    }

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }
        public function imagenes()
    {
        return $this->hasMany(RespuestaImagen::class, 'respuesta_id')->orderBy('orden');
    }

    public function videos()
    {
        return $this->hasMany(RespuestaVideo::class, 'respuesta_id')->orderBy('orden');
    }
}