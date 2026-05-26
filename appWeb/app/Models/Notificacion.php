<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Notificacion extends Model
{
    use HasUuids;

    protected $table = 'notificaciones';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    const UPDATED_AT = null;

    protected $fillable = [
        'usuario_id',
        'tipo',
        'titulo',
        'mensaje',
        'datos',
        'leida',
        'enviada_push',
        'enviada_email',
        'datos_json',
    ];

    protected $casts = [
        'datos' => 'array',
        'leida' => 'boolean',
        'enviada_push' => 'boolean',
        'enviada_email' => 'boolean',
        'created_at' => 'datetime',
        'datos_json' => 'array',
    ];

    protected $appends = ['datos_json'];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }
    public function datos()
    {
        return $this->hasMany(NotificacionDato::class, 'notificacion_id');
    }

    public function getDatosJsonAttribute()
    {
        $map = [];
        $datos = $this->relationLoaded('datos') ? $this->datos : null;
        if ($datos === null) {
            $datos = $this->datos()->get();
        }
        if ($datos !== null) {
            foreach ($datos as $dato) {
                if (isset($dato->clave)) {
                    $map[$dato->clave] = $dato->valor;
                }
            }
        }
        return $map;
    }
}