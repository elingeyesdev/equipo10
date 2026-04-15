<?php



namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Categoria extends Model
{
    use HasUuids;

    protected $table = 'categorias';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';
    const UPDATED_AT = null;

    protected $fillable = [
        'nombre', 'icono', 'color', 'descripcion', 'activo'
    ];

    protected $casts = [
        'activo' => 'boolean',        
        'created_at' => 'datetime'
    ];

    public function reportes()
    {
        return $this->hasMany(Reporte::class, 'categoria_id');
    }
}