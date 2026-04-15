<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ExpansionReporte extends Model
{
    use HasUuids;

    protected $table = 'expansiones_reporte';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'reporte_id',
        'cuadrante_original_id',
        'cuadrante_expandido_id',
        'nivel',
        'fecha_expansion'
    ];

    protected $casts = [
        'nivel' => 'integer',
        'fecha_expansion' => 'datetime'
    ];

    public function reporte()
    {
        return $this->belongsTo(Reporte::class, 'reporte_id');
    }

    public function cuadranteOriginal()
    {
        return $this->belongsTo(Cuadrante::class, 'cuadrante_original_id');
    }

    public function cuadranteExpandido()
    {
        return $this->belongsTo(Cuadrante::class, 'cuadrante_expandido_id');
    }
}