
@extends('layouts.app')

@section('title', 'Editar Roles')
@section('page-title', 'Editar Roles de Usuario')

@section('content')
<div class="row">
    <div class="col-md-8 mx-auto">
        
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-header bg-white border-0 py-3">
                <h5 class="mb-0">
                    <i class="bi bi-person-circle text-primary me-2"></i>
                    Usuario: {{ $user->display_name ?? ($user->name ?? $user->nombre) }}
                </h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <p class="mb-2"><strong>Email:</strong> {{ $user->email }}</p>
                        <p class="mb-2"><strong>ID:</strong> {{ $user->id }}</p>
                        <p class="mb-0">
                            <strong>Tipo:</strong> 
                            @if($user->type === 'web')
                                <span class="badge bg-primary"><i class="bi bi-globe me-1"></i>Web</span>
                            @else
                                <span class="badge bg-success"><i class="bi bi-phone me-1"></i>App</span>
                            @endif
                        </p>
                    </div>
                    <div class="col-md-6">
                        <p class="mb-2"><strong>Roles Actuales:</strong></p>
                        @if($user->roles->count() > 0)
                            @foreach($user->roles as $role)
                                @if($role->name === 'administrador')
                                    <span class="badge bg-danger me-1">
                                        <i class="bi bi-shield-check me-1"></i>{{ ucfirst($role->name) }}
                                    </span>
                                @elseif($role->name === 'editor')
                                    <span class="badge bg-warning me-1">
                                        <i class="bi bi-pencil-square me-1"></i>{{ ucfirst($role->name) }}
                                    </span>
                                @else
                                    <span class="badge bg-info me-1">
                                        <i class="bi bi-person me-1"></i>{{ ucfirst($role->name) }}
                                    </span>
                                @endif
                            @endforeach
                        @else
                            <span class="badge bg-secondary">Sin roles asignados</span>
                        @endif
                    </div>
                </div>
            </div>
        </div>

        
        <div class="card border-0 shadow-sm">
            <div class="card-header bg-white border-0 py-3">
                <h5 class="mb-0">
                    <i class="bi bi-shield-lock text-primary me-2"></i>
                    Asignar Roles
                </h5>
            </div>
            <div class="card-body">
                <form action="{{ route('users.roles.update', $user->id) }}" method="POST">
                    @csrf
                    @method('PUT')
                    <input type="hidden" name="type" value="{{ $user->type }}">

                    <div class="mb-4">
                        <label class="form-label fw-bold">Selecciona los roles para este usuario:</label>
                        <div class="row mt-3">
                            @foreach($roles as $role)
                            <div class="col-md-4 mb-3">
                                <div class="card border h-100 role-card" 
                                     style="cursor: pointer; transition: all 0.3s;"
                                     onclick="toggleRole('{{ $role->name }}')">
                                    <div class="card-body">
                                        <div class="form-check">
                                            <input class="form-check-input" 
                                                   type="checkbox" 
                                                   name="roles[]" 
                                                   value="{{ $role->name }}" 
                                                   id="role_{{ $role->id }}"
                                                   {{ $user->hasRole($role->name) ? 'checked' : '' }}
                                                   onchange="this.closest('.role-card').style.opacity = this.checked ? '1' : '0.7'">
                                            <label class="form-check-label fw-bold" for="role_{{ $role->id }}">
                                                @if($role->name === 'administrador')
                                                    <i class="bi bi-shield-check text-danger me-2"></i>
                                                    <span class="text-danger">{{ ucfirst($role->name) }}</span>
                                                @elseif($role->name === 'editor')
                                                    <i class="bi bi-pencil-square text-warning me-2"></i>
                                                    <span class="text-warning">{{ ucfirst($role->name) }}</span>
                                                @else
                                                    <i class="bi bi-person text-info me-2"></i>
                                                    <span class="text-info">{{ ucfirst($role->name) }}</span>
                                                @endif
                                            </label>
                                        </div>
                                        <small class="text-muted d-block mt-2">
                                            @if($role->name === 'administrador')
                                                Acceso completo al sistema
                                            @elseif($role->name === 'editor')
                                                Puede crear y editar contenido
                                            @else
                                                Acceso básico de lectura
                                            @endif
                                        </small>
                                    </div>
                                </div>
                            </div>
                            @endforeach
                        </div>
                    </div>

                    <div class="d-flex justify-content-between">
                        <a href="{{ route('users.roles.index') }}" class="btn btn-secondary">
                            <i class="bi bi-arrow-left me-2"></i>Volver
                        </a>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check-circle me-2"></i>Guardar Cambios
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<style>
    .role-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 4px 8px rgba(0,0,0,0.1);
    }
    
    .role-card input[type="checkbox"]:checked + label {
        color: var(--primary-color);
    }
</style>

<script>
    function toggleRole(roleName) {
        const checkbox = document.querySelector('input[value="' + roleName + '"]');
        if (checkbox) {
            checkbox.checked = !checkbox.checked;
            checkbox.dispatchEvent(new Event('change'));
        }
    }
    
    // Inicializar opacidad de las tarjetas según el estado del checkbox
    document.addEventListener('DOMContentLoaded', function() {
        document.querySelectorAll('.role-card input[type="checkbox"]').forEach(function(checkbox) {
            checkbox.closest('.role-card').style.opacity = checkbox.checked ? '1' : '0.7';
        });
    });
</script>
@endsection

