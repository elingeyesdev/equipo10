
@extends('layouts.app')

@section('title', 'Notificaciones')
@section('page-title', 'Gestión de Notificaciones')

@section('content')

<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-primary bg-opacity-10 p-3">
                            <i class="bi bi-bell fs-4 text-primary"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total Notificaciones</h6>
                        <h3 class="mb-0 fw-bold">{{ $notificaciones->total() ?? $notificaciones->count() }}</h3>
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
                            <i class="bi bi-bell-fill fs-4 text-warning"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">No Leídas</h6>
                        <h3 class="mb-0 fw-bold">{{ collect($notificaciones->items())->where('leida', false)->count() }}</h3>
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
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Leídas</h6>
                        <h3 class="mb-0 fw-bold">{{ collect($notificaciones->items())->where('leida', true)->count() }}</h3>
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
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Tasa Lectura</h6>
                        <h3 class="mb-0 fw-bold">
                            @php
                                $total = $notificaciones->total() ?? $notificaciones->count();
                                $leidas = collect($notificaciones->items())->where('leida', true)->count();
                                $tasa = $total > 0 ? round(($leidas / $total) * 100, 1) : 0;
                            @endphp
                            {{ $tasa }}%
                        </h3>
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
                    <i class="bi bi-bell text-primary me-2"></i>
                    Centro de Notificaciones
                </h5>
                <p class="text-muted small mb-0 mt-1">Gestiona todas las notificaciones del sistema</p>
            </div>
        </div>
    </div>
    <div class="card-body p-0">
        <div class="list-group list-group-flush">
            @forelse($notificaciones as $notificacion)
            <div class="list-group-item {{ !$notificacion->leida ? 'bg-light' : '' }} border-0 py-3 px-4" style="transition: all 0.2s ease;">
                <div class="d-flex w-100 justify-content-between align-items-start">
                    <div class="flex-grow-1">
                        <div class="d-flex align-items-start mb-2">
                            <div class="flex-shrink-0 me-3">
                                <div class="rounded-circle bg-{{ !$notificacion->leida ? 'primary' : 'secondary' }}-subtle p-2">
                                    <i class="bi bi-bell{{ !$notificacion->leida ? '-fill' : '' }} text-{{ !$notificacion->leida ? 'primary' : 'secondary' }}"></i>
                                </div>
                            </div>
                            <div class="flex-grow-1">
                                <div class="d-flex align-items-center mb-1">
                                    <h6 class="mb-0 me-2 fw-bold">{{ $notificacion->titulo }}</h6>
                            @if(!$notificacion->leida)
                                        <span class="badge bg-primary-subtle text-primary border border-primary">
                                            <i class="bi bi-circle-fill me-1" style="font-size: 0.5rem;"></i>Nueva
                                        </span>
                                    @endif
                                </div>
                                <p class="mb-2 text-muted">{{ $notificacion->mensaje }}</p>
                                <div class="d-flex align-items-center">
                                    <div class="d-flex align-items-center me-3">
                                        @if($notificacion->usuario->avatar_url ?? false)
                                            <img src="{{ $notificacion->usuario->avatar_url }}" class="rounded-circle me-2" width="24" height="24" alt="Avatar">
                                        @else
                                            <div class="rounded-circle bg-primary text-white d-flex align-items-center justify-content-center me-2" style="width: 24px; height: 24px; font-size: 10px;">
                                                {{ substr($notificacion->usuario->nombre ?? 'U', 0, 1) }}
                                            </div>
                            @endif
                        <small class="text-muted">
                                            <i class="bi bi-person me-1"></i>{{ $notificacion->usuario->nombre ?? 'Sistema' }}
                                        </small>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="flex-shrink-0 ms-3 text-end">
                        <small class="text-muted d-block mb-1">
                            <i class="bi bi-calendar3 me-1"></i>{{ $notificacion->created_at->format('d/m/Y') }}
                        </small>
                        <small class="text-muted d-block">
                            <i class="bi bi-clock me-1"></i>{{ $notificacion->created_at->diffForHumans() }}
                        </small>
                    </div>
                </div>
            </div>
            @empty
            <div class="list-group-item border-0 py-5">
                <div class="text-center">
                    <div class="mb-3">
                        <i class="bi bi-inbox fs-1 text-muted"></i>
                    </div>
                    <h5 class="text-muted">No hay notificaciones</h5>
                    <p class="text-muted small">Las notificaciones aparecerán aquí cuando haya actividad en el sistema</p>
                </div>
            </div>
            @endforelse
        </div>
        
        @if(method_exists($notificaciones, 'links'))
        <div class="card-footer bg-white border-0 py-3">
            <div class="d-flex justify-content-center">
            {{ $notificaciones->links() }}
            </div>
        </div>
        @endif
    </div>
</div>

<style>
    .list-group-item:hover {
        background-color: #f8f9fa !important;
        transform: translateX(5px);
    }
</style>
@endsection