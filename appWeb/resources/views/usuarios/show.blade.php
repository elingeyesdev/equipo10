

@extends('layouts.app')

@section('title', 'Ver Usuario')
@section('page-title', 'Detalle del Usuario')

@section('content')
<div class="row">
    <div class="col-md-8 mx-auto">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><i class="bi bi-person me-2"></i>{{ $usuario->nombre }}</h5>
                <div>
                    <a href="{{ route('usuarios.edit', $usuario->id) }}" class="btn btn-warning btn-sm">
                        <i class="bi bi-pencil"></i> Editar
                    </a>
                    <a href="{{ route('usuarios.index') }}" class="btn btn-secondary btn-sm">
                        <i class="bi bi-arrow-left"></i> Volver
                    </a>
                </div>
            </div>
            <div class="card-body">
                <div class="row mb-4">
                    <div class="col-md-12 text-center mb-3">
                        @if($usuario->avatar_url)
                            <img src="{{ $usuario->avatar_url }}" class="rounded-circle" width="120" height="120">
                        @else
                            <div class="rounded-circle bg-primary text-white d-inline-flex align-items-center justify-content-center" style="width: 120px; height: 120px; font-size: 3rem;">
                                {{ substr($usuario->nombre, 0, 1) }}
                            </div>
                        @endif
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Email</label>
                        <p class="fw-bold">{{ $usuario->email }}</p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Teléfono</label>
                        <p class="fw-bold">{{ $usuario->telefono ?? 'No especificado' }}</p>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Puntos de Ayuda</label>
                        <p><span class="badge bg-info" style="font-size: 1.2rem;">{{ $usuario->puntos_ayuda }} pts</span></p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Estado</label>
                        <p>
                            @if($usuario->activo)
                                <span class="badge bg-success">Activo</span>
                            @else
                                <span class="badge bg-danger">Inactivo</span>
                            @endif
                        </p>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Fecha de Registro</label>
                        <p class="fw-bold">{{ $usuario->fecha_registro->format('d/m/Y H:i') }}</p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Última Actualización</label>
                        <p class="fw-bold">{{ $usuario->updated_at->format('d/m/Y H:i') }}</p>
                    </div>
                </div>

                <hr>

                <h6 class="mb-3"><i class="bi bi-file-earmark-text me-2"></i>Reportes del Usuario</h6>
                <div class="row">
                    <div class="col-md-4">
                        <div class="card bg-light">
                            <div class="card-body text-center">
                                <h3 class="text-primary">{{ $usuario->reportes->count() }}</h3>
                                <p class="mb-0 text-muted">Total Reportes</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card bg-light">
                            <div class="card-body text-center">
                                <h3 class="text-danger">{{ $usuario->reportes->where('tipo_reporte', 'perdido')->count() }}</h3>
                                <p class="mb-0 text-muted">Perdidos</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card bg-light">
                            <div class="card-body text-center">
                                <h3 class="text-success">{{ $usuario->reportes->where('tipo_reporte', 'encontrado')->count() }}</h3>
                                <p class="mb-0 text-muted">Encontrados</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection