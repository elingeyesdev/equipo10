
@extends('layouts.app')

@section('title', 'Gestión de Roles')
@section('page-title', 'Gestión de Roles y Usuarios')

@section('content')

<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-primary bg-opacity-10 p-3">
                            <i class="bi bi-people fs-4 text-primary"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem;">Total Usuarios</h6>
                        <h3 class="mb-0 fw-bold">{{ $allUsers->count() }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-danger bg-opacity-10 p-3">
                            <i class="bi bi-shield-check fs-4 text-danger"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem;">Administradores</h6>
                        <h3 class="mb-0 fw-bold">{{ $allUsers->filter(fn($u) => $u['model']->hasRole('administrador'))->count() }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-warning bg-opacity-10 p-3">
                            <i class="bi bi-pencil-square fs-4 text-warning"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem;">Editores</h6>
                        <h3 class="mb-0 fw-bold">{{ $allUsers->filter(fn($u) => $u['model']->hasRole('editor'))->count() }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-info bg-opacity-10 p-3">
                            <i class="bi bi-person fs-4 text-info"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem;">Sin Roles</h6>
                        <h3 class="mb-0 fw-bold">{{ $allUsers->filter(fn($u) => $u['roles']->isEmpty())->count() }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>


@if(session('success'))
<div class="alert alert-success alert-dismissible fade show" role="alert">
    <i class="bi bi-check-circle me-2"></i>{{ session('success') }}
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
</div>
@endif


<div class="card border-0 shadow-sm">
    <div class="card-header bg-white border-0 py-3">
        <div class="row align-items-center">
            <div class="col">
                <h5 class="mb-0 fw-bold">
                    <i class="bi bi-shield-lock text-primary me-2"></i>
                    Gestión de Roles de Usuarios
                </h5>
                <p class="text-muted small mb-0 mt-1">Asigna y gestiona los roles de los usuarios del sistema</p>
            </div>
        </div>
    </div>
    <div class="card-body p-4">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead class="table-light">
                    <tr>
                        <th>Usuario</th>
                        <th>Email</th>
                        <th>Tipo</th>
                        <th>Roles Actuales</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($allUsers as $userData)
                    <tr>
                        <td>
                            <div class="d-flex align-items-center">
                                <div class="rounded-circle bg-primary text-white d-flex align-items-center justify-content-center me-3" 
                                     style="width: 40px; height: 40px; font-weight: bold;">
                                    {{ strtoupper(substr($userData['name'], 0, 1)) }}
                                </div>
                                <div>
                                    <strong class="d-block">{{ $userData['name'] }}</strong>
                                    <small class="text-muted">ID: {{ substr($userData['id'], 0, 8) }}...</small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <i class="bi bi-envelope text-muted me-2"></i>
                            {{ $userData['email'] }}
                        </td>
                        <td>
                            @if($userData['type'] === 'web')
                                <span class="badge bg-primary">
                                    <i class="bi bi-globe me-1"></i>Web
                                </span>
                            @else
                                <span class="badge bg-success">
                                    <i class="bi bi-phone me-1"></i>App
                                </span>
                            @endif
                        </td>
                        <td>
                            @if($userData['roles']->count() > 0)
                                @foreach($userData['roles'] as $role)
                                    @if($role->name === 'administrador')
                                        <span class="badge bg-danger me-1 mb-1">
                                            <i class="bi bi-shield-check me-1"></i>{{ ucfirst($role->name) }}
                                        </span>
                                    @elseif($role->name === 'editor')
                                        <span class="badge bg-warning me-1 mb-1">
                                            <i class="bi bi-pencil-square me-1"></i>{{ ucfirst($role->name) }}
                                        </span>
                                    @else
                                        <span class="badge bg-info me-1 mb-1">
                                            <i class="bi bi-person me-1"></i>{{ ucfirst($role->name) }}
                                        </span>
                                    @endif
                                @endforeach
                            @else
                                <span class="badge bg-secondary">
                                    <i class="bi bi-x-circle me-1"></i>Sin roles
                                </span>
                            @endif
                        </td>
                        <td>
                            <a href="{{ route('users.roles.edit', ['id' => $userData['id'], 'type' => $userData['type']]) }}" class="btn btn-sm btn-primary">
                                <i class="bi bi-pencil me-1"></i>Gestionar Roles
                            </a>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="text-center py-5">
                            <i class="bi bi-inbox fs-1 text-muted"></i>
                            <h5 class="text-muted mt-3">No hay usuarios registrados</h5>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection

