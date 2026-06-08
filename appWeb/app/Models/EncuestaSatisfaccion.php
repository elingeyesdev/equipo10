<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EncuestaSatisfaccion extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'encuestas_satisfaccion';

    protected $fillable = [
        'reporte_id',
        'usuario_id',
        'puntuacion',
        'comentario',
    ];

    public function reporte()
    {
        return $this->belongsTo(Reporte::class);
    }

    public function usuario()
    {
        return $this->belongsTo(Usuario::class);
    }
}
