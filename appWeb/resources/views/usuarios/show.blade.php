

@extends('layouts.app')

@section('title', 'Ver usuario')
@section('page-title', 'Detalle del usuario')

@section('content')
<div class="row">
    <div class="col-md-8 mx-auto">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">{{ $usuario->nombre }}</h5>
                <div class="d-flex gap-2">
                    <a href="{{ route('usuarios.edit', $usuario->id) }}" class="btn btn-warning btn-sm">Editar</a>
                    <a href="{{ route('usuarios.index') }}" class="btn btn-secondary btn-sm">Volver</a>
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
                        <label class="text-muted small">Puntos de ayuda</label>
                        <p><span class="badge" style="background:#5388CB;color:white;font-size:1.1rem;">{{ $usuario->puntos_ayuda }} pts</span></p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Estado</label>
                        <p>
                            @if($usuario->activo)
                                <span class="badge" style="background:#3F7AC5;color:white;">Activo</span>
                            @else
                                <span class="badge" style="background:#DFDFDF;color:#3F4B5B;">Inactivo</span>
                            @endif
                        </p>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Fecha de registro</label>
                        <p class="fw-bold">{{ $usuario->fecha_registro->format('d/m/Y H:i') }}</p>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="text-muted small">Última actualización</label>
                        <p class="fw-bold">{{ $usuario->updated_at->format('d/m/Y H:i') }}</p>
                    </div>
                </div>

                <hr>

                <h6 class="mb-3">Reportes del usuario</h6>
                <div class="row">
                    <div class="col-md-4">
                        <div class="card" style="background:#3F7AC5;">
                            <div class="card-body text-center">
                                <h3 class="text-white fw-bold">{{ $usuario->reportes->count() }}</h3>
                                <p class="mb-0 text-white opacity-85">Total reportes</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card" style="background:#EF4444;">
                            <div class="card-body text-center">
                                <h3 class="text-white fw-bold">{{ $usuario->reportes->where('tipo_reporte', 'perdido')->count() }}</h3>
                                <p class="mb-0 text-white opacity-85">Perdidos</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card" style="background:#16A34A;">
                            <div class="card-body text-center">
                                <h3 class="text-white fw-bold">{{ $usuario->reportes->where('tipo_reporte', 'encontrado')->count() }}</h3>
                                <p class="mb-0 text-white opacity-85">Encontrados</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection