<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Grupo extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'grupos';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'cuadrante_id',
        'nombre',
        'descripcion',
        'imagen_url',
        'publico',
        'requiere_aprobacion',
        'miembros_count',
        'reportes_activos_count',
        'reportes_resueltos_count',
    ];

    protected $casts = [
        'publico' => 'boolean',
        'requiere_aprobacion' => 'boolean',
        'miembros_count' => 'integer',
        'reportes_activos_count' => 'integer',
        'reportes_resueltos_count' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $attributes = [
        'publico' => true,
        'requiere_aprobacion' => false,
        'miembros_count' => 0,
        'reportes_activos_count' => 0,
        'reportes_resueltos_count' => 0,
    ];

    
    
    

    
    public function cuadrante()
    {
        return $this->belongsTo(Cuadrante::class);
    }

    
    public function miembros()
    {
        return $this->belongsToMany(Usuario::class, 'grupo_miembros', 'grupo_id', 'usuario_id')
            ->withPivot('rol', 'notificaciones_activas', 'joined_at');
    }

    public function usuarios()
    {
        return $this->belongsToMany(Usuario::class, 'grupo_miembros', 'grupo_id', 'usuario_id')
            ->withPivot('rol', 'notificaciones_activas', 'joined_at')
            ->using(GrupoMiembro::class);  // ← Esto le dice que use el modelo pivot
    }

    
    public function reportes()
    {
        return $this->hasManyThrough(
            Reporte::class,           
            Cuadrante::class,         
            'id',                     
            'cuadrante_id',          
            'cuadrante_id',          
            'id'                      
        );
    }

    
    public function reportesActivos()
    {
        return $this->reportes()->where('estado', 'activo');
    }

    
    public function reportesResueltos()
    {
        return $this->reportes()->where('estado', 'resuelto');
    }

    
    public function reportesPerdidos()
    {
        return $this->reportes()->where('tipo_reporte', 'perdido');
    }

    
    public function reportesEncontrados()
    {
        return $this->reportes()->where('tipo_reporte', 'encontrado');
    }

    
    
    

    
    public function scopePublicos($query)
    {
        return $query->where('publico', true);
    }

    
    public function scopePrivados($query)
    {
        return $query->where('publico', false);
    }

    
    public function scopeConAprobacion($query)
    {
        return $query->where('requiere_aprobacion', true);
    }

    
    public function scopePorCuadrante($query, $cuadranteId)
    {
        return $query->where('cuadrante_id', $cuadranteId);
    }

    
    public function scopeMasActivos($query)
    {
        return $query->orderBy('reportes_activos_count', 'desc');
    }

    
    public function scopeMasPopulares($query)
    {
        return $query->orderBy('miembros_count', 'desc');
    }

    
    
    

    
    public function esPublico()
    {
        return $this->publico === true;
    }

    
    public function esPrivado()
    {
        return $this->publico === false;
    }

    
    public function requiereAprobacion()
    {
        return $this->requiere_aprobacion === true;
    }

    
    public function esMiembro($usuarioId)
    {
        return $this->miembros()->where('usuario_id', $usuarioId)->exists();
    }

    
    public function esAdmin($usuarioId)
    {
        return $this->miembros()
            ->where('usuario_id', $usuarioId)
            ->wherePivot('rol', 'admin')
            ->exists();
    }

    
    public function esModerador($usuarioId)
    {
        return $this->miembros()
            ->where('usuario_id', $usuarioId)
            ->wherePivot('rol', 'moderador')
            ->exists();
    }

    
    public function rolUsuario($usuarioId)
    {
        $miembro = $this->miembros()->where('usuario_id', $usuarioId)->first();
        return $miembro ? $miembro->pivot->rol : null;
    }

    
    public function agregarMiembro($usuarioId, $rol = 'miembro')
    {
        if (!$this->esMiembro($usuarioId)) {
            $this->miembros()->attach($usuarioId, [
                'rol' => $rol,
                'joined_at' => now()
            ]);
            $this->increment('miembros_count');
            return true;
        }
        return false;
    }

    
    public function eliminarMiembro($usuarioId)
    {
        if ($this->esMiembro($usuarioId)) {
            $this->miembros()->detach($usuarioId);
            $this->decrement('miembros_count');
            return true;
        }
        return false;
    }

    
    public function actualizarRolMiembro($usuarioId, $nuevoRol)
    {
        if ($this->esMiembro($usuarioId)) {
            $this->miembros()->updateExistingPivot($usuarioId, ['rol' => $nuevoRol]);
            return true;
        }
        return false;
    }

    
    public function actualizarContadores()
    {
        $this->update([
            'miembros_count' => $this->miembros()->count(),
            'reportes_activos_count' => $this->reportesActivos()->count(),
            'reportes_resueltos_count' => $this->reportesResueltos()->count(),
        ]);
    }

    
    
    

    
    public function getImagenAttribute()
    {
        return $this->imagen_url ?? 'https://via.placeholder.com/300x300?text=' . urlencode($this->nombre);
    }

    
    public function getInicialesAttribute()
    {
        $palabras = explode(' ', $this->nombre);
        if (count($palabras) >= 2) {
            return strtoupper(substr($palabras[0], 0, 1) . substr($palabras[1], 0, 1));
        }
        return strtoupper(substr($this->nombre, 0, 2));
    }
}