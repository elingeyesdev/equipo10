
@extends('layouts.app')

@section('title', 'Usuarios')
@section('page-title', 'Gestión de Usuarios')

@section('content')

<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle d-flex align-items-center justify-content-center" style="width:52px;height:52px;background:#3F7AC5;">
                            <i class="bi bi-people-fill fs-4 text-white"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total usuarios</h6>
                        <h3 class="mb-0 fw-bold">{{ $usuarios->count() }}</h3>
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
                        <div class="rounded-circle d-flex align-items-center justify-content-center" style="width:52px;height:52px;background:#5388CB;">
                            <i class="bi bi-check-circle-fill fs-4 text-white"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Activos</h6>
                        <h3 class="mb-0 fw-bold">{{ $usuarios->where('activo', true)->count() }}</h3>
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
                        <div class="rounded-circle d-flex align-items-center justify-content-center" style="width:52px;height:52px;background:#6796D1;">
                            <i class="bi bi-trophy-fill fs-4 text-white"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total puntos</h6>
                        <h3 class="mb-0 fw-bold">{{ number_format($usuarios->sum('puntos_ayuda'), 0, ',', '.') }}</h3>
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
                        <div class="rounded-circle d-flex align-items-center justify-content-center" style="width:52px;height:52px;background:#87ABDA;">
                            <i class="bi bi-bar-chart-fill fs-4 text-white"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Promedio puntos</h6>
                        <h3 class="mb-0 fw-bold">{{ $usuarios->count() > 0 ? round($usuarios->avg('puntos_ayuda'), 1) : 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>


<div class="card border-0 shadow-sm">
    <div class="card-header bg-white border-0 py-3">
        <div class="row align-items-center">
            <div class="col">
                <h5 class="mb-0 fw-bold">
                    <i class="bi bi-people-fill text-primary me-2"></i>
                    Catálogo de usuarios
                </h5>
                <p class="text-muted small mb-0 mt-1">Administra y gestiona todos los usuarios del sistema</p>
            </div>
            <div class="col-auto">
                <a href="{{ route('usuarios.create') }}" class="btn btn-primary px-4">
                    Nuevo usuario
        </a>
            </div>
        </div>
    </div>
    <div class="card-body p-4">
        <div class="table-responsive">
            <table class="table table-hover data-table align-middle">
                <thead class="table-light">
                    <tr>
                        <th>Usuario</th>
                        <th>Email</th>
                        <th>Teléfono</th>
                        <th>Puntos</th>
                        <th>Reportes</th>
                        <th>Estado</th>
                        <th>Fecha Registro</th>
                        <th width="150px">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($usuarios as $usuario)
                    <tr>
                        <td>
                            <div class="d-flex align-items-center gap-3">
                                @if($usuario->avatar_url)
                                    <img src="{{ $usuario->avatar_url }}" class="rounded-circle flex-shrink-0" width="40" height="40" alt="Avatar">
                                @else
                                    <div class="rounded-circle bg-primary text-white d-flex align-items-center justify-content-center flex-shrink-0" style="width:40px;height:40px;font-size:16px;font-weight:bold;">
                                        {{ substr($usuario->nombre, 0, 1) }}
                                    </div>
                                @endif
                                <div style="min-width:0;">
                                    <strong class="d-block" style="word-break:break-word;">{{ $usuario->nombre }}</strong>
                                    <small class="text-muted">ID: {{ substr($usuario->id, 0, 8) }}...</small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="d-flex align-items-center">
                                <i class="bi bi-envelope text-muted me-2"></i>
                                <span>{{ $usuario->email }}</span>
                            </div>
                        </td>
                        <td>
                            @if($usuario->telefono)
                                <div class="d-flex align-items-center">
                                    <i class="bi bi-telephone text-muted me-2"></i>
                                    <span>{{ $usuario->telefono }}</span>
                                </div>
                            @else
                                <span class="text-muted">N/A</span>
                            @endif
                        </td>
                        <td>
                            <span class="badge" style="background:#5388CB;color:white;">
                                <i class="bi bi-trophy-fill me-1"></i>{{ number_format($usuario->puntos_ayuda ?? 0, 0, ',', '.') }} pts
                            </span>
                        </td>
                        <td>
                            <span class="badge" style="background:#3F7AC5;color:white;">
                                <i class="bi bi-file-earmark-text-fill me-1"></i>{{ $usuario->reportes->count() ?? 0 }}
                            </span>
                        </td>
                        <td>
                            @if($usuario->activo)
                                <span class="badge" style="background:#3F7AC5;color:white;">
                                    Activo
                                </span>
                            @else
                                <span class="badge" style="background:#DFDFDF;color:#3F4B5B;">
                                    Inactivo
                                </span>
                            @endif
                        </td>
                        <td>
                            <small class="text-muted">
                                {{ $usuario->fecha_registro->format('d/m/Y') }}<br>
                                {{ $usuario->fecha_registro->format('H:i') }}
                            </small>
                        </td>
                        <td>
                            <div class="d-flex gap-2">
                                <a href="{{ route('usuarios.show', $usuario->id) }}" class="btn btn-sm d-flex align-items-center justify-content-center" style="background:#5388CB;color:white;width:34px;height:34px;padding:0;" title="Ver">
                                    <i class="bi bi-eye-fill"></i>
                                </a>
                                <a href="{{ route('usuarios.edit', $usuario->id) }}" class="btn btn-sm d-flex align-items-center justify-content-center" style="background:#E9C978;color:#2B333D;width:34px;height:34px;padding:0;" title="Editar">
                                    <i class="bi bi-pencil-fill"></i>
                                </a>
                                <form action="{{ route('usuarios.destroy', $usuario->id) }}" method="POST" class="d-inline" onsubmit="return confirmarEliminacion(this)">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-sm d-flex align-items-center justify-content-center" style="background:#EF4444;color:white;width:34px;height:34px;padding:0;" title="Eliminar">
                                        <i class="bi bi-trash-fill"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="8" class="text-center py-5">
                            <div class="mb-3">
                                <i class="bi bi-inbox fs-1 text-muted"></i>
                            </div>
                            <h5 class="text-muted">No hay usuarios registrados</h5>
                            <p class="text-muted small">Comienza creando tu primer usuario</p>
                            <a href="{{ route('usuarios.create') }}" class="btn btn-primary mt-2">
                                <i class="bi bi-plus-circle me-2"></i> Crear Usuario
                            </a>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

<style>
    .table tbody tr {
        transition: all 0.2s ease;
    }
    
    .table tbody tr:hover {
        background-color: #f8f9fa;
        transform: scale(1.01);
    }
</style>
@endsection
