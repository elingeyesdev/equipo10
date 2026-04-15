<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class RespuestaVideo extends Model
{
    use HasUuids;

    protected $table = 'respuesta_videos';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    const UPDATED_AT = null;

    protected $fillable = [
        'respuesta_id',
        'url',
        'orden'
    ];

    protected $casts = [
        'orden' => 'integer',
        'created_at' => 'datetime'
    ];

    public function respuesta()
    {
        return $this->belongsTo(Respuesta::class, 'respuesta_id');
    }
}
