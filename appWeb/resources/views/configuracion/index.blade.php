
@extends('layouts.app')

@section('title', 'Configuración')
@section('page-title', 'Configuración del Sistema')

@section('content')

<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-primary bg-opacity-10 p-3">
                            <i class="bi bi-gear fs-4 text-primary"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total Configuraciones</h6>
                        <h3 class="mb-0 fw-bold">{{ $configuraciones->count() }}</h3>
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
                        <div class="rounded-circle bg-success bg-opacity-10 p-3">
                            <i class="bi bi-check-circle fs-4 text-success"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Configuradas</h6>
                        <h3 class="mb-0 fw-bold">{{ $configuraciones->whereNotNull('valor')->count() }}</h3>
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
                            <i class="bi bi-exclamation-triangle fs-4 text-warning"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Pendientes</h6>
                        <h3 class="mb-0 fw-bold">{{ $configuraciones->whereNull('valor')->count() }}</h3>
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
                            <i class="bi bi-clock-history fs-4 text-info"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Última Actualización</h6>
                        <h6 class="mb-0 fw-bold" style="font-size: 0.9rem;">
                            @if($configuraciones->max('updated_at'))
                                {{ $configuraciones->max('updated_at')->diffForHumans() }}
                            @else
                                N/A
                            @endif
                        </h6>
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
                    <i class="bi bi-gear text-primary me-2"></i>
                    Configuración del Sistema
                </h5>
                <p class="text-muted small mb-0 mt-1">Administra las configuraciones y parámetros del sistema</p>
            </div>
            <div class="col-auto">
                <a href="{{ route('configuracion.edit') }}" class="btn btn-primary rounded-pill px-4">
                    <i class="bi bi-pencil-square me-2"></i>Editar Ajustes
                </a>
            </div>
        </div>
    </div>
    <div class="card-body p-4">
        <div class="table-responsive">
            <table class="table table-hover align-middle">
                <thead class="table-light">
                    <tr>
                        <th width="200px">Clave</th>
                        <th>Valor</th>
                        <th>Descripción</th>
                        <th width="120px">Tipo</th>
                        <th width="180px">Última Actualización</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($configuraciones as $config)
                    <tr>
                        <td>
                            <div class="d-flex align-items-center">
                                <div class="flex-shrink-0 me-2">
                                    <div class="rounded bg-primary bg-opacity-10 p-2">
                                        <i class="bi bi-key text-primary"></i>
                                    </div>
                                </div>
                                <div>
                                    <code class="text-primary fw-bold">{{ $config->clave }}</code>
                                </div>
                            </div>
                        </td>
                        <td>
                            @if($config->valor)
                                <div class="d-flex align-items-center">
                                    <span class="badge bg-success-subtle text-success border border-success me-2">
                                        <i class="bi bi-check-circle-fill me-1"></i>Configurado
                                    </span>
                                    <strong class="text-dark">{{ Str::limit($config->valor, 50) }}</strong>
                                </div>
                            @else
                                <span class="badge bg-warning-subtle text-warning border border-warning">
                                    <i class="bi bi-exclamation-triangle-fill me-1"></i>Sin valor
                                </span>
                            @endif
                        </td>
                        <td>
                            <span class="text-muted">{{ $config->descripcion ?? 'Sin descripción' }}</span>
                        </td>
                        <td>
                            @php
                                $tipoColors = [
                                    'string' => 'primary',
                                    'integer' => 'info',
                                    'boolean' => 'success',
                                    'json' => 'warning',
                                    'decimal' => 'danger'
                                ];
                                $color = $tipoColors[$config->tipo] ?? 'secondary';
                            @endphp
                            <span class="badge bg-{{ $color }}-subtle text-{{ $color }} border border-{{ $color }}">
                                {{ ucfirst($config->tipo) }}
                            </span>
                        </td>
                        <td>
                            <small class="text-muted">
                                <i class="bi bi-calendar3 me-1"></i>{{ $config->updated_at->format('d/m/Y') }}<br>
                                <i class="bi bi-clock me-1"></i>{{ $config->updated_at->format('H:i') }}
                            </small>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="text-center py-5">
                            <div class="mb-3">
                                <i class="bi bi-inbox fs-1 text-muted"></i>
                            </div>
                            <h5 class="text-muted">No hay configuraciones</h5>
                            <p class="text-muted small">Las configuraciones del sistema aparecerán aquí</p>
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
    
    code {
        font-size: 0.9rem;
        padding: 0.25rem 0.5rem;
        background-color: #f8f9fa;
        border-radius: 4px;
    }
</style>
@endsection