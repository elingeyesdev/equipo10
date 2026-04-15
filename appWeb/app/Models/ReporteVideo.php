<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ReporteVideo extends Model
{
    use HasUuids;

    protected $table = 'reporte_videos';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    const UPDATED_AT = null;

    protected $fillable = [
        'reporte_id',
        'url',
        'orden'
    ];

    protected $casts = [
        'orden' => 'integer',
        'created_at' => 'datetime'
    ];

    public function reporte()
    {
        return $this->belongsTo(Reporte::class, 'reporte_id');
    }
}