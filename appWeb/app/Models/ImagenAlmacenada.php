<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ImagenAlmacenada extends Model
{
    use HasUuids;

    protected $table = 'imagenes_almacenadas';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'mime_type',
        'base64_data',
    ];
}
