<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ConfiguracionSistema extends Model
{
    protected $table = 'configuracion_sistema';
    protected $primaryKey = 'clave';
    public $incrementing = false;
    protected $keyType = 'string';
    const CREATED_AT = null;

    protected $fillable = [
        'clave', 'valor', 'descripcion', 'tipo'
    ];

    protected $casts = [
        'updated_at' => 'datetime'
    ];

    public function getValorAttribute($value)
    {
        switch ($this->tipo) {
            case 'number':
                return (float) $value;
            case 'boolean':
                return filter_var($value, FILTER_VALIDATE_BOOLEAN);
            case 'json':
                return json_decode($value, true);
            default:
                return $value;
        }
    }
}