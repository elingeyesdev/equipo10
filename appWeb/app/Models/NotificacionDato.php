<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NotificacionDato extends Model
{
    use HasUuids;

    protected $table = 'notificacion_datos';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    const UPDATED_AT = null;

    protected $fillable = [
        'notificacion_id',
        'clave',
        'valor'
    ];

    protected $casts = [
        'created_at' => 'datetime'
    ];

    public function notificacion()
    {
        return $this->belongsTo(Notificacion::class, 'notificacion_id');
    }
}
