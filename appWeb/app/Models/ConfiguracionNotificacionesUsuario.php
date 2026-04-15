<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ConfiguracionNotificacionesUsuario extends Model
{
    use HasUuids;

    protected $table = 'configuracion_notificaciones_usuario';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'usuario_id',
        'push_activo',
        'email_activo',
        'sms_activo'
    ];

    protected $casts = [
        'push_activo' => 'boolean',
        'email_activo' => 'boolean',
        'sms_activo' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }
}