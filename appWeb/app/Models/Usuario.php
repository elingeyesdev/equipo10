<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Traits\HasRoles;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;


use Laravel\Sanctum\HasApiTokens;

class Usuario extends Authenticatable
{
    use HasApiTokens, HasFactory, HasUuids, HasRoles, Notifiable;

    protected $guard_name = 'web';

    protected $table = 'usuarios';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'nombre',
        'email',
        'telefono',
        'avatar_url',
        'puntos_ayuda',
        'activo',
        'ubicacion_actual_lat',
        'ubicacion_actual_lng',
        'rol',
        'contrasena'
    ];
    
    protected $hidden = [
        'contrasena',
    ];

    protected $casts = [
        'activo' => 'boolean',
        'ubicacion_actual_lat' => 'decimal:8',
        'ubicacion_actual_lng' => 'decimal:8',
        'puntos_ayuda' => 'integer',
        'fecha_registro' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $attributes = [
        'activo' => true,
        'puntos_ayuda' => 0,
    ];

    
    
        public function getAuthPassword()
    {
        return $this->contrasena;
    }

    public function getAuthIdentifierName()
    {
        return 'email';
    }
    
    public function configuracionNotificaciones()
    {
        return $this->hasOne(ConfiguracionNotificacionesUsuario::class, 'usuario_id');
    }
    
    public function reportes()
    {
        return $this->hasMany(Reporte::class, 'usuario_id');
    }
    
    public function respuestas()
    {
        return $this->hasMany(Respuesta::class, 'usuario_id');
    }


    
    

    
    public function grupos()
    {
        return $this->belongsToMany(Grupo::class, 'grupo_miembros', 'usuario_id', 'grupo_id')
            ->withPivot('rol', 'notificaciones_activas', 'joined_at')
            ->using(GrupoMiembro::class); 
    }

    public function grupoMiembros()
    {
        return $this->hasMany(GrupoMiembro::class, 'usuario_id');
    }
    
    public function notificaciones()
    {
        return $this->hasMany(Notificacion::class, 'usuario_id');
    }

    
    protected static function boot()
    {
        parent::boot();

        
        static::deleting(function ($usuario) {
            
            // DB::table('configuracion_notificaciones_usuario')
            //     ->where('usuario_id', $usuario->id)
            //     ->delete();
        });
    }

    
    
    

    
    public function scopeActivos($query)
    {
        return $query->where('activo', true);
    }

    
    public function scopeTopColaboradores($query, $limit = 10)
    {
        return $query->orderBy('puntos_ayuda', 'desc')->limit($limit);
    }

    
    
    

    
    public function agregarPuntosAyuda($puntos)
    {
        return $this->increment('puntos_ayuda', $puntos);
    }

    
    public function estaActivo()
    {
        return $this->activo === true;
    }
}