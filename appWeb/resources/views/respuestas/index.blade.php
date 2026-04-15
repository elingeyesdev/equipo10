
@extends('layouts.app')

@section('title', 'Respuestas')
@section('page-title', 'Gestión de Respuestas')

@section('content')

<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-primary bg-opacity-10 p-3">
                            <i class="bi bi-chat-dots fs-4 text-primary"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total Respuestas</h6>
                        <h3 class="mb-0 fw-bold">{{ $respuestas->count() }}</h3>
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
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Verificadas</h6>
                        <h3 class="mb-0 fw-bold">{{ $respuestas->where('verificada', true)->count() }}</h3>
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
                            <i class="bi bi-star fs-4 text-warning"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Marcadas Útiles</h6>
                        <h3 class="mb-0 fw-bold">{{ $respuestas->where('util', true)->count() }}</h3>
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
                            <i class="bi bi-bar-chart fs-4 text-info"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Tasa Verificación</h6>
                        <h3 class="mb-0 fw-bold">{{ $respuestas->count() > 0 ? round(($respuestas->where('verificada', true)->count() / $respuestas->count()) * 100, 1) : 0 }}%</h3>
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
                    <i class="bi bi-chat-dots text-primary me-2"></i>
                    Catálogo de Respuestas
                </h5>
                <p class="text-muted small mb-0 mt-1">Gestiona todas las respuestas de los reportes</p>
            </div>
        </div>
    </div>
    
    <div class="card-body p-4">
        <div class="table-responsive">
            <table class="table table-hover data-table align-middle">
                <thead class="table-light">
                    <tr>
                        <th>Reporte</th>
                        <th>Usuario</th>
                        <th>Tipo</th>
                        <th>Mensaje</th>
                        <th>Estado</th>
                        <th>Fecha</th>
                        <th width="100px">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($respuestas as $respuesta)
                    <tr>
                        <td>
                            <div class="d-flex align-items-center">
                                <div class="flex-shrink-0 me-2">
                                    <div class="rounded bg-primary bg-opacity-10 p-2">
                                        <i class="bi bi-file-earmark-text text-primary"></i>
                                    </div>
                                </div>
                                <div class="flex-grow-1">
                                    <strong class="d-block">{{ Str::limit($respuesta->reporte->titulo ?? 'N/A', 30) }}</strong>
                                    <small class="text-muted">{{ $respuesta->reporte->tipo_reporte ?? 'N/A' }}</small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="d-flex align-items-center">
                                @if($respuesta->usuario->avatar_url ?? false)
                                    <img src="{{ $respuesta->usuario->avatar_url }}" class="rounded-circle me-2" width="32" height="32" alt="Avatar">
                                @else
                                    <div class="rounded-circle bg-primary text-white d-flex align-items-center justify-content-center me-2" style="width: 32px; height: 32px; font-size: 12px;">
                                        {{ substr($respuesta->usuario->nombre ?? 'U', 0, 1) }}
                                    </div>
                                @endif
                                <span>{{ $respuesta->usuario->nombre ?? 'N/A' }}</span>
                            </div>
                        </td>
                        <td>
                            @php
                                $tipoColors = [
                                    'avistamiento' => 'info',
                                    'encontrado' => 'success',
                                    'informacion' => 'primary',
                                    'pregunta' => 'warning'
                                ];
                                $color = $tipoColors[$respuesta->tipo_respuesta] ?? 'secondary';
                            @endphp
                            <span class="badge bg-{{ $color }}">
                                <i class="bi bi-{{ $respuesta->tipo_respuesta == 'encontrado' ? 'check-circle' : ($respuesta->tipo_respuesta == 'avistamiento' ? 'eye' : 'question-circle') }} me-1"></i>
                                {{ ucfirst($respuesta->tipo_respuesta) }}
                            </span>
                        </td>
                        <td>
                            <span class="text-muted">{{ Str::limit($respuesta->mensaje, 50) }}</span>
                        </td>
                        <td>
                            <div class="d-flex flex-column gap-1">
                            @if($respuesta->verificada)
                                    <span class="badge bg-success-subtle text-success border border-success">
                                        <i class="bi bi-check-circle-fill me-1"></i>Verificada
                                </span>
                            @endif
                            @if($respuesta->util)
                                    <span class="badge bg-warning-subtle text-warning border border-warning">
                                        <i class="bi bi-star-fill me-1"></i>Útil
                                </span>
                            @endif
                                @if(!$respuesta->verificada && !$respuesta->util)
                                    <span class="badge bg-secondary-subtle text-secondary">Pendiente</span>
                                @endif
                            </div>
                        </td>
                        <td>
                            <small class="text-muted">
                                <i class="bi bi-calendar3 me-1"></i>
                                {{ $respuesta->created_at->format('d/m/Y') }}<br>
                                <i class="bi bi-clock me-1"></i>
                                {{ $respuesta->created_at->format('H:i') }}
                            </small>
                        </td>
                        <td>
                            <div class="btn-group btn-group-sm">
                                <a href="{{ route('reportes.show', $respuesta->reporte_id ?? '#') }}" 
                                   class="btn btn-outline-info" 
                                   title="Ver Reporte">
                                    <i class="bi bi-eye"></i>
                                </a>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="7" class="text-center py-5">
                            <div class="mb-3">
                                <i class="bi bi-inbox fs-1 text-muted"></i>
                            </div>
                            <h5 class="text-muted">No hay respuestas registradas</h5>
                            <p class="text-muted small">Las respuestas aparecerán aquí cuando los usuarios respondan a reportes</p>
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