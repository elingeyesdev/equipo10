<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class CuadranteBarrio extends Model
{
    use HasUuids;

    protected $table = 'cuadrante_barrios';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    const UPDATED_AT = null;

    protected $fillable = [
        'cuadrante_id',
        'nombre_barrio'
    ];

    protected $casts = [
        'created_at' => 'datetime'
    ];

    public function cuadrante()
    {
        return $this->belongsTo(Cuadrante::class, 'cuadrante_id');
    }
}