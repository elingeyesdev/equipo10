<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ReporteImagen extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'reporte_imagenes';
    protected $primaryKey = 'id';
    
    protected $attributes = [
        'estado' => self::STATE_PENDING
    ];
    public $incrementing = false;
    protected $keyType = 'string';
    const STATE_PENDING = 'pending';
    const STATE_APPROVED = 'approved';
    const STATE_REJECTED = 'rejected';

    protected $fillable = [
        'reporte_id',
        'url',
        'orden',
        'estado'    ];

        protected $casts = [
        'orden' => 'integer',
        'created_at' => 'datetime',
        'estado' => 'string'    ];


    public function reporte()
    {
        return $this->belongsTo(Reporte::class, 'reporte_id');
    }
}
